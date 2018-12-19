//
//  SwitcherTableCell.h
//  SmartGarden
//
//  Created by Ingo Primas on 18.02.18.
//  Copyright © 2018 Bausparkasse Mainz AG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBCircularProgressBarView.h"
#import "SwitchConfig.h"

@interface SwitcherTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet MBCircularProgressBarView *circularProgressBar;
@property (strong, nonatomic) NSTimer *laufzeitTimer;
@property (strong, nonatomic) SwitchConfig *switchConfig;

- (void)initialize;
- (void)startLaufzeit;
- (void)stopLaufzeit;

@end

