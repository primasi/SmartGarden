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
        }
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void)initialize
{
    self.textLabel.text = self.switchConfig.name;
    self.detailTextLabel.text = [NSString stringWithFormat:@"Laufzeit %02i:%02i, Modus: %@", [self.switchConfig.gesamtlaufzeit intValue] / (60 * 60),([self.switchConfig.gesamtlaufzeit intValue] % (60 * 60)) / 60,[self.switchConfig.section intValue] == 2 ? ([self.switchConfig.aktiv boolValue] ? @"An" : @"Aus") : self.switchConfig.modus];
    //self.laufzeitLabel.text = [NSString stringWithFormat:@"%02i:%02i", [self.switchConfig.gesamtlaufzeit intValue] / (60 * 60),([self.switchConfig.gesamtlaufzeit intValue] % (60 * 60)) / 60];
    
    if ([self.switchConfig.gesamtlaufzeit floatValue] > 0.0f)
    {
        self.circularProgressBar.value = 100.00f * [self.switchConfig.aktuellelaufzeit floatValue] / [self.switchConfig.gesamtlaufzeit floatValue];
        self.circularProgressBar.maxValue = 100.00f;
    }
}

@end
