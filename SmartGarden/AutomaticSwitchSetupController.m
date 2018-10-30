//
//  SwitchSetupController.m
//  SmartGarden
//
//  Created by Primas, Ingo on 27.09.18.
//  Copyright © 2018 Bausparkasse Mainz AG. All rights reserved.
//

#import "AutomaticSwitchSetupController.h"

@interface AutomaticSwitchSetupController () <UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *laufzeitTextView;
@property (weak, nonatomic) IBOutlet UITextView *modusTextView;
@property (weak, nonatomic) IBOutlet UITextView *schalterartTextView;
@property (weak, nonatomic) IBOutlet UITextView *urlTextView;
@property (strong, nonatomic) NSMutableDictionary *pickerData;
@property (nonatomic, strong) UIPickerView *laufzeitPicker;
@property (nonatomic, strong) UIPickerView *modusPicker;
@property (nonatomic, strong) UIPickerView *schalterartPicker;
@property (nonatomic, strong) UIPickerView *currentPicker;
@property (weak, nonatomic) IBOutlet UINavigationItem *switchSetupNavItem;

@end

@implementation AutomaticSwitchSetupController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.switchSetupNavItem.title = self.switchConfig.name;
    
    self.pickerData = [[NSMutableDictionary alloc] init];
    
    self.laufzeitTextView.text = [NSString stringWithFormat:@"%02i Stunden %02i Minuten", [self.switchConfig.gesamtlaufzeit intValue] / (60 * 60),([self.switchConfig.gesamtlaufzeit intValue] % (60 * 60)) / 60];
    
    self.modusTextView.text = self.switchConfig.modus;
    [self.laufzeitTextView setUserInteractionEnabled:![self.switchConfig.modus isEqualToString:@"Gesamt"]];
    
    if (self.switchConfig.url == nil)
    {
        self.schalterartTextView.text = @"Intern";
    }
    else
    {
        self.schalterartTextView.text = @"Extern";
    }
    
    [self initModusPicker];
    [self initLaufzeitPicker];
    [self initSchalterartPicker];
}

- (void) initLaufzeitPicker
{
    NSMutableArray *pickerComponents = [[NSMutableArray alloc] init];
    NSMutableArray *pickerHours = [[NSMutableArray alloc] init];
    for (int hours = 0;hours < 24;hours++)
    {
        [pickerHours addObject:[NSString stringWithFormat:@"%02i h",hours]];
    }
    [pickerComponents insertObject:pickerHours atIndex:0];
    NSMutableArray *pickerMinutes = [[NSMutableArray alloc] init];
    for (int minutes = 0;minutes < 60;minutes++)
    {
        [pickerMinutes addObject:[NSString stringWithFormat:@"%02i Min",minutes]];
    }
    [pickerComponents insertObject:pickerMinutes atIndex:1];
    
    self.laufzeitPicker = [[UIPickerView alloc] init];
    self.laufzeitPicker.delegate = self;
    self.laufzeitPicker.dataSource = self;
    self.laufzeitPicker.tag = 0;
    [self.laufzeitTextView setInputView:self.laufzeitPicker];
    [self.pickerData setObject:pickerComponents forKey:[NSNumber numberWithInteger:0]];
    
    [self.laufzeitPicker selectRow:[self.switchConfig.gesamtlaufzeit intValue] / 60 inComponent:0 animated:YES];
    [self.laufzeitPicker selectRow:[self.switchConfig.gesamtlaufzeit intValue] % 60 inComponent:1 animated:YES];
    
    UIToolbar *laufzeitPickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [laufzeitPickerToolbar setTintColor:[UIColor grayColor]];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc]initWithTitle:@"Fertig" style:UIBarButtonItemStylePlain target:self action:@selector(handleDoneButton:)];
    UIBarButtonItem *title = [[UIBarButtonItem alloc]initWithTitle:@"Laufzeit" style:UIBarButtonItemStylePlain target:nil action:nil];
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc]initWithTitle:@"Abbrechen" style:UIBarButtonItemStylePlain target:self action:@selector(handleCancelButton:)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [laufzeitPickerToolbar setItems:[NSArray arrayWithObjects:title, space, cancelBtn, doneBtn, nil]];
    [self.laufzeitTextView setInputAccessoryView:laufzeitPickerToolbar];
}

- (void) initModusPicker
{
    NSMutableArray *pickerComponents = [[NSMutableArray alloc] init];
    NSMutableArray *pickerModi = [[NSMutableArray alloc] init];
    [pickerModi addObject:@"Aus"];
    [pickerModi addObject:@"Teilzeit"];
    [pickerModi addObject:@"Vollzeit"];
    [pickerComponents insertObject:pickerModi atIndex:0];
    
    self.modusPicker = [[UIPickerView alloc] init];
    self.modusPicker.delegate = self;
    self.modusPicker.dataSource = self;
    self.modusPicker.tag = 1;
    [self.modusTextView setInputView:self.modusPicker];
    [self.pickerData setObject:pickerComponents forKey:[NSNumber numberWithInteger:1]];
    
    if ([self.switchConfig.modus isEqualToString:@"Aus"])
    {
        [self.modusPicker selectRow:0 inComponent:0 animated:YES];
    }
    if ([self.switchConfig.modus isEqualToString:@"Teilzeit"])
    {
        [self.modusPicker selectRow:1 inComponent:0 animated:YES];
    }
    if ([self.switchConfig.modus isEqualToString:@"Vollzeit"])
    {
        [self.modusPicker selectRow:2 inComponent:0 animated:YES];
    }
    
    UIToolbar *modusPickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [modusPickerToolbar setTintColor:[UIColor grayColor]];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc]initWithTitle:@"Fertig" style:UIBarButtonItemStylePlain target:self action:@selector(handleDoneButton:)];
    UIBarButtonItem *title = [[UIBarButtonItem alloc]initWithTitle:@"Modus" style:UIBarButtonItemStylePlain target:nil action:nil];
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc]initWithTitle:@"Abbrechen" style:UIBarButtonItemStylePlain target:self action:@selector(handleCancelButton:)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [modusPickerToolbar setItems:[NSArray arrayWithObjects:title, space, cancelBtn, doneBtn, nil]];
    [self.modusTextView setInputAccessoryView:modusPickerToolbar];
}

- (void) initSchalterartPicker
{
    NSMutableArray *pickerComponents = [[NSMutableArray alloc] init];
    NSMutableArray *pickerSchalterart = [[NSMutableArray alloc] init];
    [pickerSchalterart addObject:@"Intern"];
    [pickerSchalterart addObject:@"Extern"];
    [pickerComponents insertObject:pickerSchalterart atIndex:0];
    
    self.schalterartPicker = [[UIPickerView alloc] init];
    self.schalterartPicker.delegate = self;
    self.schalterartPicker.dataSource = self;
    self.schalterartPicker.tag = 2;
    [self.schalterartTextView setInputView:self.schalterartPicker];
    [self.pickerData setObject:pickerComponents forKey:[NSNumber numberWithInteger:2]];
    
    if (self.switchConfig.url == nil)
    {
        [self.schalterartPicker selectRow:0 inComponent:0 animated:YES];
    }
    else
    {
        [self.schalterartPicker selectRow:1 inComponent:0 animated:YES];
    }
   
    UIToolbar *schalterartPickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [schalterartPickerToolbar setTintColor:[UIColor grayColor]];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc]initWithTitle:@"Fertig" style:UIBarButtonItemStylePlain target:self action:@selector(handleDoneButton:)];
    UIBarButtonItem *title = [[UIBarButtonItem alloc]initWithTitle:@"Modus" style:UIBarButtonItemStylePlain target:nil action:nil];
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc]initWithTitle:@"Abbrechen" style:UIBarButtonItemStylePlain target:self action:@selector(handleCancelButton:)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [schalterartPickerToolbar setItems:[NSArray arrayWithObjects:title, space, cancelBtn, doneBtn, nil]];
    [self.schalterartTextView setInputAccessoryView:schalterartPickerToolbar];
}

#pragma mark - Table view data source

#pragma mark - Navigation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.switchConfig.url == nil ? 3 : 4;
}

- (void) handleDoneButton:(id)sender
{
    if (self.currentPicker.tag == 0)
    {
        NSMutableArray* pickerComponent = [self.pickerData objectForKey:[NSNumber numberWithInteger:0]];
        self.switchConfig.gesamtlaufzeit = [NSNumber numberWithInteger:([pickerComponent[0][[self.laufzeitPicker selectedRowInComponent:0]] intValue] * 60 + [pickerComponent[1][[self.laufzeitPicker selectedRowInComponent:1]] intValue]) * 60];
        self.laufzeitTextView.text = [NSString stringWithFormat:@"%02i Stunden %02i Minuten", [pickerComponent[0][[self.laufzeitPicker selectedRowInComponent:0]] intValue],[pickerComponent[1][[self.laufzeitPicker selectedRowInComponent:1]] intValue]];
        [self.laufzeitTextView resignFirstResponder];
    }
    if (self.currentPicker.tag == 1)
    {
        NSMutableArray* pickerComponent = [self.pickerData objectForKey:[NSNumber numberWithInteger:1]][0];
        self.switchConfig.modus = pickerComponent[[self.modusPicker selectedRowInComponent:0]];
        self.modusTextView.text = pickerComponent[[self.modusPicker selectedRowInComponent:0]];
        [self.modusTextView resignFirstResponder];
    }
    if (self.currentPicker.tag == 2)
    {
        NSMutableArray* pickerComponent = [self.pickerData objectForKey:[NSNumber numberWithInteger:2]][0];
        self.switchConfig.url = [self.schalterartPicker selectedRowInComponent:0] == 0 ? nil : self.urlTextView.text;
        self.schalterartTextView.text = pickerComponent[[self.schalterartPicker selectedRowInComponent:0]];
        [self.schalterartTextView resignFirstResponder];
        [self.tableView reloadData];
    }
}

- (void) handleCancelButton:(id)sender
{
    if (self.currentPicker.tag == 0)
    {
        [self.laufzeitTextView resignFirstResponder];
    }
    if (self.currentPicker.tag == 1)
    {
        [self.modusTextView resignFirstResponder];
    }
    if (self.currentPicker.tag == 2)
    {
        [self.schalterartTextView resignFirstResponder];
    }
}

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView
{
    self.currentPicker = pickerView;
    return [[self.pickerData objectForKey:[NSNumber numberWithInteger:pickerView.tag]] count];
}

- (CGFloat)pickerView:(nonnull UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return 120;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [[self.pickerData objectForKey:[NSNumber numberWithInteger:pickerView.tag]][component] count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    return [self.pickerData objectForKey:[NSNumber numberWithInteger:pickerView.tag]][component][row];
}

@end
