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

@class SwitcherTableCell;

//NS_ASSUME_NONNULL_BEGIN

@protocol SwitcherTableCellDelegate <NSObject>

-(void)tableCellLaufzeitChanged:(SwitcherTableCell *)switcherTableCell;
-(void)tableCellSwitchChanged:(SwitcherTableCell *)switcherTableCell;
-(void)laufzeitTimerFinished:(SwitcherTableCell *)switcherTableCell;

@end

@interface SwitcherTableCell : UITableViewCell <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet MBCircularProgressBarView *circularProgressBar;
@property (weak, nonatomic) IBOutlet UILabel *laufzeitLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusView;
@property (strong, nonatomic) NSTimer *laufzeitTimer;
@property (strong, nonatomic) SwitchConfig *switchConfig;
@property (nonatomic, weak, nullable) id<SwitcherTableCellDelegate> delegate;

- (void)initialize;
- (void)startLaufzeit;
- (void)stopLaufzeit;

@end

//NS_ASSUME_NONNULL_END
