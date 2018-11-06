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
    
    self.laufzeitLabel.layer.cornerRadius = 5.0f;
    self.laufzeitLabel.layer.borderWidth = 1.0f;
    self.laufzeitLabel.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    self.statusView.layer.cornerRadius = 5.0f;
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
    self.circularProgressBar.value = [self.switchConfig.aktuellelaufzeit floatValue];
}

- (void)laufzeitTimerCallback:(NSTimer *)timer
{
    [UIView animateWithDuration:1.f animations:^
    {
        self.circularProgressBar.value += 100 / [self.switchConfig.gesamtlaufzeit floatValue];
        if (self.circularProgressBar.value >= 100)
        {
            self.circularProgressBar.value = 100.00;
            NSLog(@"Stoppe Schalter %@",self.switchConfig.nummer);
            [timer invalidate];
            //timer = nil;
        }
    }];
}

- (void)changeModus
{
    if ([self.switchConfig.section intValue] == 1)
    {
        self.switchConfig.aktiv = [NSNumber numberWithBool:![self.switchConfig.aktiv boolValue]];
        self.statusView.text = ([self.switchConfig.aktiv boolValue] ? @"An" : @"Aus");
        self.switchConfig.modus = ([self.switchConfig.aktiv boolValue] ? @"An" : @"Aus");
    }
    else
    {
        if ([self.switchConfig.modus isEqualToString:@"Aus"])
        {
            self.statusView.text = @"Vollzeit";
            self.switchConfig.modus = @"Vollzeit";
        }
        else if ([self.switchConfig.modus isEqualToString:@"Vollzeit"])
        {
            self.statusView.text = @"Teilzeit";
            self.switchConfig.modus = @"Teilzeit";
        }
        else
        {
            self.statusView.text = @"Aus";
            self.switchConfig.modus = @"Aus";
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void)initialize
{
    if ([self.switchConfig.section intValue] == 1)
    {
        self.statusView.text = ([self.switchConfig.aktiv boolValue] ? @"An" : @"Aus");
    }
    else
    {
        self.statusView.text = self.switchConfig.modus;
    }
     
    self.textLabel.text = self.switchConfig.name;
    self.tag = [self.switchConfig.nummer intValue];
    
    self.laufzeitLabel.text = [NSString stringWithFormat:@"%02i:%02i", [self.switchConfig.gesamtlaufzeit intValue] / (60 * 60),([self.switchConfig.gesamtlaufzeit intValue] % (60 * 60)) / 60];
}

@end
