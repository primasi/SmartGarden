//
//  SwitcherTableCell.m
//  SmartGarden
//
//  Created by Ingo Primas on 18.02.18.
//  Copyright © 2018 Bausparkasse Mainz AG. All rights reserved.
//

#import "SwitcherTableCell.h"
#import "SmartGardenConfig.h"

@implementation SwitcherTableCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.laufzeitTextView.layer.cornerRadius = 10.0f;
    self.laufzeitTextView.layer.borderWidth = 1.0f;
    self.laufzeitTextView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    self.statusView.layer.cornerRadius = 10.0f;
    self.statusView.layer.borderWidth = 1.0f;
    self.statusView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    self.circularProgressBar.value = 0;
    self.circularProgressBar.maxValue = 100;
}

- (void)startLaufzeit
{
    NSLog(@"Starte Schalter %@",self.switchConfig.nummer);
    self.circularProgressBar.value = 0;
    if ([self.switchConfig.gesamtlaufzeit floatValue] > 0)
    {
        [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        self.laufzeitTimer = [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector(laufzeitTimerCallback:) userInfo: nil repeats: YES];
        [[NSRunLoop currentRunLoop] addTimer:self.laufzeitTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)stopLaufzeit
{
    NSLog(@"Stoppe Schalter %@",self.switchConfig.nummer);
    [self.laufzeitTimer invalidate];
    self.laufzeitTimer = nil;
    //[self.delegate laufzeitTimerFinished:self];
}

- (void)laufzeitTimerCallback:(NSTimer *)timer
{
    [UIView animateWithDuration:1.f animations:^
    {
        self.circularProgressBar.value += 100 / [self.switchConfig.gesamtlaufzeit floatValue];
        if (self.circularProgressBar.value >= 100)
        {
            self.circularProgressBar.value = 100;
            [self stopLaufzeit];
        }
    }];
}

- (void)changeModus
{
    if ([self.switchConfig.section intValue] == 1)
    {
        self.switchConfig.aktiv = [NSNumber numberWithBool:![self.switchConfig.aktiv boolValue]];
        self.laufzeitTextView.editable = ![self.switchConfig.aktiv boolValue];
        self.statusView.text = ([self.switchConfig.aktiv boolValue] ? @"An" : @"Aus");
        self.switchConfig.modus = ([self.switchConfig.aktiv boolValue] ? @"An" : @"Aus");
    }
    else
    {
        if ([self.switchConfig.modus isEqualToString:@"Aus"])
        {
            self.statusView.text = @"Gesamt";
            self.switchConfig.modus = @"Gesamt";
            self.laufzeitTextView.editable = false;
            self.laufzeitTextView.userInteractionEnabled = false;
        }
        else if ([self.switchConfig.modus isEqualToString:@"Gesamt"])
        {
            self.statusView.text = @"Einzel";
            self.switchConfig.modus = @"Einzel";
            self.laufzeitTextView.editable = true;
            self.laufzeitTextView.userInteractionEnabled = true;
        }
        else
        {
            self.statusView.text = @"Aus";
            self.switchConfig.modus = @"Aus";
            self.laufzeitTextView.editable = true;
            self.laufzeitTextView.userInteractionEnabled = true;
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void)initialize
{
    self.laufzeitTextView.editable = NO;
    [self.laufzeitTextView setUserInteractionEnabled:NO];
    if ([self.switchConfig.section intValue] == 1)
    {
        //self.laufzeitTextView.editable = ![self.switchConfig.aktiv boolValue];
        [self.laufzeitTextView setUserInteractionEnabled:![self.switchConfig.aktiv boolValue]];
        self.statusView.text = ([self.switchConfig.aktiv boolValue] ? @"An" : @"Aus");
    }
    else
    {
        self.statusView.text = self.switchConfig.modus;
        //[self.laufzeitTextView setUserInteractionEnabled:![self.switchConfig.modus isEqualToString:@"Gesamt"]];
    }
     
    self.textLabel.text = [NSString stringWithFormat:@"Schalter %i",[self.switchConfig.nummer intValue]];
    self.tag = [self.switchConfig.nummer intValue];
    
    self.laufzeitTextView.text = [NSString stringWithFormat:@"%02i:%02i", [self.switchConfig.gesamtlaufzeit intValue] / 60,[self.switchConfig.gesamtlaufzeit intValue] % 60];
    
    /*
    self.pickerData = [[NSMutableArray alloc] init];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setHour:[self.switchConfig.gesamtlaufzeit intValue] / 60];
    [components setMinute:[self.switchConfig.gesamtlaufzeit intValue] % 60];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [calendar dateFromComponents:components];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    self.laufzeitTextView.text = [NSString stringWithFormat:@"%@", [formatter stringFromDate:date]];
    
    NSMutableArray *pickerHours = [[NSMutableArray alloc] init];
    for (int hours = 0;hours < 24;hours++)
    {
        [pickerHours addObject:[NSString stringWithFormat:@"%02i h",hours]];
    }
    [self.pickerData insertObject:pickerHours atIndex:0];
    NSMutableArray *pickerMinutes = [[NSMutableArray alloc] init];
    for (int minutes = 0;minutes < 60;minutes++)
    {
        [pickerMinutes addObject:[NSString stringWithFormat:@"%02i Min",minutes]];
    }
    [self.pickerData insertObject:pickerMinutes atIndex:1];
    
    self.stunde = [NSNumber numberWithInt:[self.switchConfig.gesamtlaufzeit intValue] / 60];
    self.minute = [NSNumber numberWithInt:[self.switchConfig.gesamtlaufzeit intValue] % 60];
    
    UIPickerView *startzeitPicker = [[UIPickerView alloc] init];
    startzeitPicker.delegate = self;
    startzeitPicker.dataSource = self;
    [startzeitPicker selectRow:[self.stunde intValue] inComponent:0 animated:YES];
    [startzeitPicker selectRow:[self.minute intValue] inComponent:1 animated:YES];
    [self.laufzeitTextView setInputView:startzeitPicker];
    UIToolbar *startzeitPickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [startzeitPickerToolbar setTintColor:[UIColor grayColor]];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc]initWithTitle:@"Fertig" style:UIBarButtonItemStylePlain target:self action:@selector(handleDoneButton)];
    UIBarButtonItem *title = [[UIBarButtonItem alloc]initWithTitle:self.textLabel.text style:UIBarButtonItemStylePlain target:nil action:nil];
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc]initWithTitle:@"Abbrechen" style:UIBarButtonItemStylePlain target:self action:@selector(handleCancelButton)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [startzeitPickerToolbar setItems:[NSArray arrayWithObjects:title, space, cancelBtn, doneBtn, nil]];
    [self.laufzeitTextView setInputAccessoryView:startzeitPickerToolbar];
     */
}
/*
- (void) handleDoneButton
{
    self.switchConfig.gesamtlaufzeit = [NSNumber numberWithInteger:[self.stunde intValue] * 60 + [self.minute intValue]];
    [self.delegate tableCellLaufzeitChanged:self];
}

- (void) handleCancelButton
{
    self.stunde = [NSNumber numberWithInt:[self.switchConfig.gesamtlaufzeit intValue] / 60];
    self.minute = [NSNumber numberWithInt:[self.switchConfig.gesamtlaufzeit intValue] % 60];
    [self.laufzeitTextView resignFirstResponder];
}

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView
{
    return [self.pickerData count];
}

- (CGFloat)pickerView:(nonnull UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return 120;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [((NSMutableArray*)self.pickerData[component]) count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    NSMutableArray* pickerComponent = self.pickerData[component];
    return pickerComponent[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (component)
    {
        case 0:
            self.stunde = [NSNumber numberWithInteger:row];
            break;
        case 1:
            self.minute = [NSNumber numberWithInteger:row];
            break;
    }
}
*/
@end
