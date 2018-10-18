//
//  ViewController.m
//  SmartGarden
//
//  Created by Primas, Ingo on 28.07.17.
//  Copyright © 2017 Bausparkasse Mainz AG. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "SmartGardenConfig.h"
#import "SwitcherTableCell.h"
#import "NSArray_Sorting.h"
#import "RNBlurModalView.h"
#import "NachrichtenViewController.h"
#import "StartzeitenViewController.h"
#import "AutomaticSwitchSetupController.h"
#import "ManualSwitchSetupController.h"

#define BASE_URL @"172.20.10.14"
//#define BASE_URL @"192.168.2.17"
//#define BASE_URL @"192.168.0.30"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, SwitcherTableCellDelegate>

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nachrichtenButton;
@property (weak, nonatomic) IBOutlet UITextField *startzeitTextField;
@property (weak, nonatomic) IBOutlet UITextField *serverzeitTextField;
@property (weak, nonatomic) IBOutlet UITextField *countdownTextField;
@property (weak, nonatomic) IBOutlet MBCircularProgressBarView *progressView;
@property (strong, nonatomic) NSInputStream *inputStream;
@property (strong, nonatomic) NSOutputStream *outputStream;
@property (strong, nonatomic) SmartGardenConfig *smartGardenConfig;
@property (strong, nonatomic) NSMutableArray *sectionsText;
@property (strong, nonatomic) UITapGestureRecognizer *doubleTap;
@property (strong, nonatomic) NSTimer *serverzeitTimer;
@property (strong, nonatomic) NSTimer *timeoutTimer;
@property (strong, nonatomic) UIViewController *segueViewController;
@property NSStreamEvent streamEvent;

- (IBAction)startButtonClicked:(id)sender;

@end

@implementation ViewController

- (void)serverzeitTimerCallback:(NSTimer *)timer
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd.MM.yyyy HH:mm:ss"];
    NSDate *servertime = [formatter dateFromString:self.smartGardenConfig.serverzeit];
    self.smartGardenConfig.serverzeit = [formatter stringFromDate:[servertime dateByAddingTimeInterval:1.0]];
    self.serverzeitTextField.text = [self.smartGardenConfig.serverzeit stringByReplacingOccurrencesOfString:@" " withString:@" - "];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    if ([self.smartGardenConfig.startzeiten count] > 0)
    {
        NSDate *startzeit = nil;
        NSTimeInterval time_interval = 0;
        NSDateComponents *servertime_components = [calendar components:NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:servertime];
        for (Startzeit *temp_startzeit in self.smartGardenConfig.startzeiten)
        {
            NSDateComponents *startzeit_components = [[NSDateComponents alloc] init];
            startzeit_components.hour = [temp_startzeit.stunde integerValue];
            startzeit_components.minute = [temp_startzeit.minute integerValue];
            startzeit_components.second = 0;
            startzeit_components.month = servertime_components.month;
            startzeit_components.year = servertime_components.year;
            NSInteger start_weekday = [temp_startzeit.wochentag integerValue] + 1;
            if (servertime_components.weekday < start_weekday)
            {
                startzeit_components.day = servertime_components.day + (start_weekday - servertime_components.weekday);
            }
            else if (servertime_components.weekday == start_weekday)
            {
                if (servertime_components.hour > startzeit_components.hour)
                {
                    startzeit_components.day = servertime_components.day + 7;
                }
                else if (servertime_components.hour == startzeit_components.hour)
                {
                    if (servertime_components.minute > startzeit_components.minute)
                    {
                        startzeit_components.day = servertime_components.day + 7;
                    }
                    else if (servertime_components.minute == startzeit_components.minute)
                    {
                        if (servertime_components.second > startzeit_components.second)
                        {
                            startzeit_components.day = servertime_components.day + 7;
                        }
                        else
                        {
                            startzeit_components.day = servertime_components.day;
                        }
                    }
                    else
                    {
                        startzeit_components.day = servertime_components.day;
                    }
                }
                else
                {
                    startzeit_components.day = servertime_components.day;
                }
            }
            else
            {
                startzeit_components.day = servertime_components.day + (start_weekday + (7 - servertime_components.weekday));
            }
            NSDate *starttime = [calendar dateFromComponents:startzeit_components];
            if (time_interval == 0 || ([starttime timeIntervalSinceDate:servertime] < time_interval))
            {
                startzeit = starttime;
                time_interval = [starttime timeIntervalSinceDate:servertime];
            }
        }
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour |NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:servertime toDate:startzeit options:0];
        self.countdownTextField.text = [NSString stringWithFormat:@"%02lih %02lim %02lis",components.hour,components.minute,components.second];
        
        NSMutableArray *weekdays = [[NSMutableArray alloc] initWithObjects:@"Sonntag", @"Montag", @"Dienstag", @"Mittwoch", @"Donnerstag", @"Freitag", @"Samstag", nil];
        components = [calendar components:(NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:startzeit];
        self.startzeitTextField.text = [NSString stringWithFormat:@"%@ um %02li:%02li Uhr",weekdays[components.weekday - 1],components.hour,components.minute];
    }
    else
    {
        self.startzeitTextField.text = @"";
        self.countdownTextField.text = @"";
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingPushNotification:) name:@"incomingPushNotification" object:nil];
    
    self.smartGardenConfig = [[SmartGardenConfig alloc] init];
    self.smartGardenConfig.startzeiten = [[NSMutableArray alloc] init];
    
    self.sectionsText = [NSMutableArray arrayWithObjects:@"Automatisch", @"Manuell", nil];
    
    [self initNetworkCommunication];
    
    self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    self.doubleTap.numberOfTapsRequired = 2;
    self.doubleTap.numberOfTouchesRequired = 1;
    [self.tableView addGestureRecognizer:self.doubleTap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
    
    self.tableView.refreshControl = [[UIRefreshControl alloc] init];
    self.tableView.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Status neu laden..."];
    [self.tableView.refreshControl addTarget:self action:@selector(refreshStatus) forControlEvents:UIControlEventValueChanged];
}

- (void)refreshStatus
{
    if (![self sendMessage:@"Status"])
    {
        [self.tableView.refreshControl endRefreshing];
        RNBlurModalView *modal = [[RNBlurModalView alloc] initWithTitle:@"Fehler!" message:@"Der Server ist zur Zeit nicht erreichbar!"];
        [modal show];
    }
}

- (void)didEnterBackground
{
    [self.outputStream close];
    [self.inputStream close];
}

- (void)willEnterForeground
{
    if (![self sendMessage:@"Status"])
    {
        RNBlurModalView *modal = [[RNBlurModalView alloc] initWithTitle:@"Fehler!" message:@"Der Server ist zur Zeit nicht erreichbar!"];
        [modal show];
    }
}
- (void)viewWillAppear:(BOOL)animated
{
    if ([self.segueViewController isKindOfClass:[StartzeitenViewController class]])
    {
        self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
        NSString *result = [NSString stringWithFormat:@"Uebertragen %@",[self.smartGardenConfig classToJson]];
        [self sendMessage:result];
    }
    if ([self.segueViewController isKindOfClass:[NachrichtenViewController class]])
    {
        
    }
    if ([self.segueViewController isKindOfClass:[AutomaticSwitchSetupController class]])
    {
        self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
        NSString *result = [NSString stringWithFormat:@"Uebertragen %@",[self.smartGardenConfig classToJson]];
        [self sendMessage:result];
        [self.smartGardenConfig updateGesamtlaufzeit];
        [self.tableView reloadData];
    }
    if ([self.segueViewController isKindOfClass:[ManualSwitchSetupController class]])
    {
        ManualSwitchSetupController *controller = (ManualSwitchSetupController*)self.segueViewController;
        self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
        NSString *result = [NSString stringWithFormat:@"Uebertragen %@",[self.smartGardenConfig classToJson]];
        [self sendMessage:result];
        [self.smartGardenConfig updateGesamtlaufzeit];
        [self.tableView reloadData];
        [self sendMessage:[NSString stringWithFormat:@"Schalte %li %i",(long)controller.switchConfig.nummer,[controller.switchConfig.aktiv intValue]]];
    }
}

- (void)initNetworkCommunication
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    if ([self.outputStream streamStatus] == NSStreamStatusOpen && [self.inputStream streamStatus] != NSStreamStatusOpen)
    {
        [self.outputStream close];
    }
    if ([self.outputStream streamStatus] != NSStreamStatusOpen && [self.inputStream streamStatus] == NSStreamStatusOpen)
    {
        [self.inputStream close];
    }
    if ([self.outputStream streamStatus] != NSStreamStatusOpen && [self.inputStream streamStatus] != NSStreamStatusOpen)
    {
        CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)BASE_URL, 7777, &readStream, &writeStream);
        
        self.inputStream = (NSInputStream *)CFBridgingRelease(readStream);
        self.outputStream = (NSOutputStream *)CFBridgingRelease(writeStream);
        
        [self.inputStream setDelegate:self];
        [self.outputStream setDelegate:self];
        
        [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        [self.inputStream open];
        [self.outputStream open];
    }
}

- (void)timeoutTimerCallback:(NSTimer *)timer
{
    [self.outputStream close];
    [self.inputStream close];
    self.streamEvent = NSStreamEventErrorOccurred;
}

- (BOOL)sendMessage:(NSString *)message
{
    [self initNetworkCommunication];
    
    //self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval: 5 target: self selector: @selector(timeoutTimerCallback:) userInfo: nil repeats: NO];
    //[[NSRunLoop mainRunLoop] addTimer:self.timeoutTimer forMode:NSRunLoopCommonModes];
    
    //(while (self.streamEvent != NSStreamEventOpenCompleted && self.streamEvent != NSStreamEventErrorOccurred);
 
    if ([self.outputStream streamStatus] == NSStreamStatusOpen)
    {
        NSData *data = [[NSData alloc] initWithData:[message dataUsingEncoding:NSASCIIStringEncoding]];
        [self.outputStream write:[data bytes] maxLength:[data length]];
        return true;
    }
    else
    {
        return false;
    }
}

- (void) enableConfigure:(BOOL)enable
{
    if (enable)
    {
        [self enableSection:0 enable:YES];
        self.doubleTap.enabled = YES;
    }
    else
    {
        [self enableSection:0 enable:NO];
        self.doubleTap.enabled = NO;
    }
}

/**
 stream events
 */
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    switch (streamEvent)
    {
        case NSStreamEventOpenCompleted:
            if ([theStream isKindOfClass:[NSInputStream class]])
            {
                NSLog(@"InputStream opened for %@",BASE_URL);
            }
            if ([theStream isKindOfClass:[NSOutputStream class]])
            {
                NSLog(@"OutputStream opened for %@",BASE_URL);
            }
            break;
            
        case NSStreamEventHasBytesAvailable:
            NSLog(@"Has Bytes available");
            if (theStream == _inputStream)
            {
                uint8_t buffer[2048];
                long len;
                
                while ([_inputStream hasBytesAvailable])
                {
                    len = [_inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0)
                    {
                        NSString *receiveString = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        NSLog(@"Server said: %@", receiveString);
                        
                        if ([receiveString hasPrefix:@"Schalte"])
                        {
                            NSArray *switchInformation = [receiveString componentsSeparatedByString:@" "];
                            SwitcherTableCell *cell = [self cellForSwitchNumber:[[switchInformation objectAtIndex:1] intValue]];
                            if ([[switchInformation objectAtIndex:2] intValue] == 1)
                            {
                                [cell startLaufzeit];
                            }
                            else
                            {
                                [cell stopLaufzeit];
                            }
                        }
                        if ([receiveString hasPrefix:@"Start"])
                        {
                            [self.startButton setTitle:@"Stop"];
                            [self enableConfigure:NO];
                            SwitcherTableCell *cell = [self cellForSwitchNumber:[[self.smartGardenConfig nextActiveSwitchConfig:nil].nummer intValue]];
                            [cell startLaufzeit];
                        }
                        if ([receiveString hasPrefix:@"Stop"])
                        {
                            [self.startButton setTitle:@"Start"];
                            [self enableConfigure:YES];
                            SwitcherTableCell *cell = [self cellForSwitchNumber:[[self.smartGardenConfig nextActiveSwitchConfig:nil].nummer intValue]];
                            [cell stopLaufzeit];
                        }
                        if ([receiveString hasPrefix:@"Uebertragen"])
                        {
                            
                        }
                        if ([receiveString hasPrefix:@"Status"])
                        {
                            NSError *jsonError;
                            
                            //receiveString = [receiveString stringByReplacingOccurrencesOfString:@"(null)" withString:@"null"];
                            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:[[receiveString substringFromIndex:[@"Status" length] + 1] dataUsingEncoding:NSASCIIStringEncoding] options:NSJSONReadingMutableContainers error:&jsonError];
                            if (jsonError == nil)
                            {
                                [self.smartGardenConfig initWithJSON:jsonObject];
                                [self.tableView reloadData];
                                
                                if (self.serverzeitTimer != nil)
                                {
                                    [self.serverzeitTimer invalidate];
                                }
                                self.serverzeitTimer = [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector(serverzeitTimerCallback:) userInfo: nil repeats: YES];
                                [[NSRunLoop mainRunLoop] addTimer:self.serverzeitTimer forMode:NSRunLoopCommonModes];
                                
                                [self enableConfigure:![self.smartGardenConfig.automatikAktiviert boolValue]];
                                if ([self.smartGardenConfig.automatikAktiviert boolValue])
                                {
                                    [self.startButton setTitle:@"Stop"];
                                }
                                else
                                {
                                    [self.startButton setTitle:@"Start"];
                                }
                            }
                            [self.tableView.refreshControl endRefreshing];
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            theStream = nil;
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"Closing stream...");
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            theStream = nil;
            break;
            
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"Has Space available");
            if (self.streamEvent == NSStreamEventOpenCompleted)
            {
                [self sendMessage:@"Status"];
            }
            break;
            
        case NSStreamEventNone:
            NSLog(@"None");
            break;
            
        default:
            NSLog(@"Unknown event");
    }
    self.streamEvent = streamEvent;
}

#pragma mark - UITableViewDataSource

- (SwitcherTableCell *)cellForSwitchNumber:(int) number
{
    for (int section = 0;section < self.tableView.numberOfSections;section++)
    {
        for (int row = 0;row < [self.tableView numberOfRowsInSection:section];row++)
        {
            SwitcherTableCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            if ([cell.switchConfig.nummer intValue] == number)
            {
                return cell;
            }
        }
    }
    return nil;
}

- (void)enableSection:(int) section enable:(BOOL)enable
{
    for (int row = 0;row < [self.tableView numberOfRowsInSection:section];row++)
    {
        SwitcherTableCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
        cell.laufzeitTextView.editable = enable;
        [cell setUserInteractionEnabled:enable];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int switchesSection0 = 0;
    int switchesSection1 = 0;
    
    for (SwitchConfig *switchConfig in [self.smartGardenConfig.switches allValues])
    {
        switchesSection0 += ([switchConfig.section intValue] == 0 ? 1 : 0);
        switchesSection1 += ([switchConfig.section intValue] == 1 ? 1 : 0);
    }
    return section == 0 ? switchesSection0 : switchesSection1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SwitcherTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SwitcherTableCell"];
    if (cell == nil)
    {
        cell = [[SwitcherTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SwitcherTableCell"];
    }
    
    cell.delegate = self;
    cell.switchConfig = [self.smartGardenConfig switchForIndexPath:indexPath];
    [cell initialize];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sectionsText[section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    return 60;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return tableView.sectionHeaderHeight;
}

// The event handling method
- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    if (self.tableView.editing)
    {
        self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
        NSString *result = [NSString stringWithFormat:@"Uebertragen %@",[self.smartGardenConfig classToJson]];
        [self sendMessage:result];
    }
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    
}

- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return !((UISwitch *)[tableView cellForRowAtIndexPath:indexPath].accessoryView).on;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableview shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SwitcherTableCell *cell = (SwitcherTableCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO animated:YES];
    [self performSegueWithIdentifier:indexPath.section == 1 ? @"ManualSwitchSetup" :@"AutomaticSwitchSetup" sender:cell];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void) tableView:(UITableView *)tableView didEndReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
    SwitcherTableCell *cell = (SwitcherTableCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    cell.switchConfig.modus = @"Aus";
    cell.switchConfig.section = [NSNumber numberWithInteger:indexPath.section];
}

- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
}

#pragma mark - UITableViewDelegate

#pragma mark - UIBarButtonItem

- (IBAction)statusButtonClicked:(id)sender
{
    if (![self sendMessage:@"Status"])
    {
        RNBlurModalView *modal = [[RNBlurModalView alloc] initWithTitle:@"Fehler!" message:@"Der Server ist zur Zeit nicht erreichbar!"];
        [modal show];
    }
}

- (IBAction)startButtonClicked:(id)sender
{
    [self sendMessage:self.startButton.title];
}

- (void)tableCellLaufzeitChanged:(nonnull SwitcherTableCell *)switcherTableCell
{
    [self.smartGardenConfig updateGesamtlaufzeit];
    [self.tableView reloadData];
    self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
    NSString *result = [NSString stringWithFormat:@"Uebertragen %@",[self.smartGardenConfig classToJson]];
    [self sendMessage:result];
}

- (void)tableCellSwitchChanged:(nonnull SwitcherTableCell *)switcherTableCell
{
    if ([switcherTableCell.switchConfig.section intValue] == 1)
    {
        [self sendMessage:[NSString stringWithFormat:@"Schalte %li %i",(long)switcherTableCell.tag,[switcherTableCell.switchConfig.aktiv intValue]]];
    }
    else
    {
        [self.smartGardenConfig updateGesamtlaufzeit];
        [self.tableView reloadData];
        self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
        NSString *result = [NSString stringWithFormat:@"Uebertragen %@",[self.smartGardenConfig classToJson]];
        [self sendMessage:result];
    }
}

- (void)laufzeitTimerFinished:(nonnull SwitcherTableCell *)switcherTableCell
{
    SwitcherTableCell *cell = [self cellForSwitchNumber:[[self.smartGardenConfig nextActiveSwitchConfig:switcherTableCell.switchConfig].nummer intValue]];
    [cell startLaufzeit];
}

- (void) incomingPushNotification:(NSNotification*)notification
{
    NSArray *switchInformation = [[[notification userInfo] objectForKey:@"Schalter"] componentsSeparatedByString:@" "];
    if (switchInformation != nil)
    {
        SwitcherTableCell *cell = [self cellForSwitchNumber:[[switchInformation objectAtIndex:0] intValue]];
        if (cell != nil)
        {
            if ([[switchInformation objectAtIndex:1] intValue] == 1)
            {
                [cell startLaufzeit];
            }
            else
            {
                [cell stopLaufzeit];
            }
        }
    }
    int badge = [[[[notification userInfo] objectForKey:@"aps"] objectForKey:@"badge"] intValue];
    [self.nachrichtenButton setTitle:[NSString stringWithFormat:@"Nachrichten (%i)",badge]];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Nachrichten"])
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        self.smartGardenConfig.badge = [NSNumber numberWithInt:0];
        self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
        NSString *result = [NSString stringWithFormat:@"Uebertragen %@",[self.smartGardenConfig classToJson]];
        [self sendMessage:result];
    }
    if ([segue.identifier isEqualToString:@"Startzeiten"])
    {
        ((StartzeitenViewController*)[segue destinationViewController]).smartGardenConfig = self.smartGardenConfig;
    }
    if ([segue.identifier isEqualToString:@"AutomaticSwitchSetup"])
    {
        ((AutomaticSwitchSetupController*)[segue destinationViewController]).switchConfig = ((SwitcherTableCell*)sender).switchConfig;
    }
    if ([segue.identifier isEqualToString:@"ManualSwitchSetup"])
    {
        ((ManualSwitchSetupController*)[segue destinationViewController]).switchConfig = ((SwitcherTableCell*)sender).switchConfig;
    }
    self.segueViewController = [segue destinationViewController];
}

@end
