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
    
    self.circularProgressBar.value = 0.0f;
    self.circularProgressBar.maxValue = 100.00f;
}

- (void)startLaufzeit
{
    NSLog(@"Starte Schalter %@",self.switchConfig.nummer);
    self.circularProgressBar.value = 0.0f;
    if ([self.switchConfig.gesamtlaufzeit floatValue] > 0.0f)
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
    self.circularProgressBar.value = 100.00f * [self.switchConfig.aktuellelaufzeit floatValue] / [self.switchConfig.gesamtlaufzeit floatValue];
}

- (void)laufzeitTimerCallback:(NSTimer *)timer
{
    [UIView animateWithDuration:1.0f animations:^
    {
        self.switchConfig.aktuellelaufzeit = [NSNumber numberWithInt:[self.switchConfig.aktuellelaufzeit intValue] + 1];
        self.circularProgressBar.value = 100.00f * [self.switchConfig.aktuellelaufzeit floatValue] / [self.switchConfig.gesamtlaufzeit floatValue];
        if (self.circularProgressBar.value >= 100.00f)
        {
            self.circularProgressBar.value = 100.00f;
            NSLog(@"Stoppe Timer Schalter %@",self.switchConfig.nummer);
            [timer invalidate];
            //timer = nil;
        }
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void)initialize
{
    if ([self.switchConfig.section intValue] == 2)
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
    
    if ([self.switchConfig.gesamtlaufzeit floatValue] > 0.0f)
    {
        self.circularProgressBar.value = 100.00f * [self.switchConfig.aktuellelaufzeit floatValue] / [self.switchConfig.gesamtlaufzeit floatValue];
        self.circularProgressBar.maxValue = 100.00f;
    }
}

@end
