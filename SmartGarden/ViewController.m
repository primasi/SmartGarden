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
@property NSString *startzeit_textlabel;
@property NSString *startzeit_detaillabel;
@property BOOL sending;

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
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        if ([self.smartGardenConfig.automatikAktiviert boolValue])
        {
            self.startzeit_detaillabel = [NSString stringWithFormat:@"Verbleibende Zeit bis zum Start: %02lih %02lim %02lis",components.hour,components.minute,components.second];
        }
        else
        {
            self.startzeit_detaillabel = @"";
        }
        NSMutableArray *weekdays = [[NSMutableArray alloc] initWithObjects:@"Sonntag", @"Montag", @"Dienstag", @"Mittwoch", @"Donnerstag", @"Freitag", @"Samstag", nil];
        components = [calendar components:(NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:startzeit];
        self.startzeit_textlabel = [NSString stringWithFormat:@"Nächster Start: %@ um %02li:%02li Uhr",weekdays[components.weekday - 1],components.hour,components.minute];
        [self.tableView reloadData];
    }
    else
    {
        self.startzeit_detaillabel = @"";
        self.startzeit_textlabel = @"Keine Startzeit konfiguriert.";
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(incomingPushNotification:) name:@"incomingPushNotification" object:nil];
    
    self.sending = false;
    
    self.smartGardenConfig = [[SmartGardenConfig alloc] init];
    self.smartGardenConfig.startzeiten = [[NSMutableArray alloc] init];
    
    self.sectionsText = [NSMutableArray arrayWithObjects:@"Startzeit", @"Automatisch", @"Manuell", nil];
    
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
    self.smartGardenConfig.action = @"Status";
    if (![self sendMessage])
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
    [self initNetworkCommunication];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([self.segueViewController isKindOfClass:[StartzeitenViewController class]])
    {
        self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
        self.smartGardenConfig.action = @"Uebertragen";
        [self sendMessage];
    }
    if ([self.segueViewController isKindOfClass:[NachrichtenViewController class]])
    {
        self.smartGardenConfig.badge = [NSNumber numberWithInt:0];
        [self.nachrichtenButton setTitle:[NSString stringWithFormat:@"Nachrichten (%i)",[self.smartGardenConfig.badge intValue]]];
        self.smartGardenConfig.action = @"Uebertragen";
        [self sendMessage];
    }
    if ([self.segueViewController isKindOfClass:[AutomaticSwitchSetupController class]])
    {
        AutomaticSwitchSetupController *controller = (AutomaticSwitchSetupController*)self.segueViewController;
        self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
        [self.smartGardenConfig.switches setObject:controller.switchConfig forKey:controller.switchConfig.nummer];
        [self.smartGardenConfig updateGesamtlaufzeit];
        self.smartGardenConfig.action = @"Uebertragen";
        [self sendMessage];
        [self.tableView reloadData];
    }
    if ([self.segueViewController isKindOfClass:[ManualSwitchSetupController class]])
    {
        ManualSwitchSetupController *controller = (ManualSwitchSetupController*)self.segueViewController;
        self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
        self.smartGardenConfig.action = @"Schalte";
        self.smartGardenConfig.control = controller.switchConfig.nummer;
        self.smartGardenConfig.state = controller.switchConfig.aktiv;
        [self.smartGardenConfig.switches setObject:controller.switchConfig forKey:controller.switchConfig.nummer];
        [self.smartGardenConfig updateGesamtlaufzeit];
        [self sendMessage];
        [self.tableView reloadData];
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

- (BOOL)sendMessage
{
    [self initNetworkCommunication];
    
    if ([self.outputStream streamStatus] == NSStreamStatusOpen && !self.sending)
    {
        NSData *data = [[NSData alloc] initWithData:[[self.smartGardenConfig classToJson] dataUsingEncoding:NSASCIIStringEncoding]];
        [self.outputStream write:[data bytes] maxLength:[data length]];
        self.sending = true;
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
                        NSError *jsonError;
                        
                        NSString *receiveString = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        NSLog(@"Server said: %@", receiveString);
                        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:[receiveString dataUsingEncoding:NSASCIIStringEncoding] options:NSJSONReadingMutableContainers error:&jsonError];
                        if (jsonError == nil)
                        {
                            [self.smartGardenConfig initWithJSON:jsonObject];
                            if ([self.smartGardenConfig.action isEqualToString:@"Schalte"])
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
                            if ([self.smartGardenConfig.action isEqualToString:@"Start"])
                            {
                                [self.startButton setTitle:@"Stop"];
                                [self enableConfigure:NO];
                                /*
                                SwitchConfig *switchConfig = [self.smartGardenConfig nextActiveSwitchConfig:nil];
                                if (switchConfig != nil)
                                {
                                    SwitcherTableCell *cell = [self cellForSwitchNumber:[switchConfig.nummer intValue]];
                                    [cell startLaufzeit];
                                }
                                */
                            }
                            if ([self.smartGardenConfig.action isEqualToString:@"Stop"])
                            {
                                [self.startButton setTitle:@"Start"];
                                [self enableConfigure:YES];
                                /*
                                SwitchConfig *switchConfig = [self.smartGardenConfig nextActiveSwitchConfig:nil];
                                if (switchConfig != nil)
                                {
                                    SwitcherTableCell *cell = [self cellForSwitchNumber:[switchConfig.nummer intValue]];
                                    [cell stopLaufzeit];
                                }
                                */
                            }
                            if ([self.smartGardenConfig.action isEqualToString:@"Status"])
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
                                [self.nachrichtenButton setTitle:[NSString stringWithFormat:@"Nachrichten (%i)",[self.smartGardenConfig.badge intValue]]];
                            }
                        }
                        [self.tableView.refreshControl endRefreshing];
                        [self.tableView reloadData];
                        self.sending = false;
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
                self.smartGardenConfig.action = @"Status";
                [self sendMessage];
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
    for (int section = 1;section < self.tableView.numberOfSections;section++)
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

- (NSMutableArray *)cellForSwitchModus:(NSString *) modus
{
    NSMutableArray *cells = [[NSMutableArray alloc] init];
    
    for (int section = 1;section < self.tableView.numberOfSections;section++)
    {
        for (int row = 0;row < [self.tableView numberOfRowsInSection:section];row++)
        {
            SwitcherTableCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            if ([cell.switchConfig.modus isEqualToString:modus])
            {
                [cells addObject:cell];
            }
        }
    }
    return cells;
}

- (void)enableSection:(int) section enable:(BOOL)enable
{
    for (int row = 0;row < [self.tableView numberOfRowsInSection:section];row++)
    {
        SwitcherTableCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
        [cell setUserInteractionEnabled:enable];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int switchesSection1 = 0;
    int switchesSection2 = 0;
    
    for (SwitchConfig *switchConfig in [self.smartGardenConfig.switches allValues])
    {
        switchesSection1 += ([switchConfig.section intValue] == 1 ? 1 : 0);
        switchesSection2 += ([switchConfig.section intValue] == 2 ? 1 : 0);
    }
    
    int rows = 0;
    switch (section)
    {
        case 0:
            rows = 1;
            break;
        case 1:
            rows = switchesSection1;
            break;
        case 2:
            rows = switchesSection2;
    }
    return rows;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StartzeitTableCell"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StartzeitTableCell"];
        }
        cell.textLabel.text = self.startzeit_textlabel;
        cell.detailTextLabel.text = self.startzeit_detaillabel;
        return cell;
    }
    else
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
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
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
        self.smartGardenConfig.action = @"Uebertragen";
        [self sendMessage];
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
    
    NSString *identifier = nil;
    switch (indexPath.section)
    {
        case 0:
            identifier = @"Startzeiten";
            break;
        case 1:
            identifier = @"AutomaticSwitchSetup";
            break;
        case 2:
            identifier = @"ManualSwitchSetup";
    }
    [self performSegueWithIdentifier:identifier sender:cell];
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

- (IBAction)startButtonClicked:(id)sender
{
    self.smartGardenConfig.action = self.startButton.title;
    self.smartGardenConfig.automatikAktiviert = [NSNumber numberWithBool:[self.smartGardenConfig.action isEqualToString:@"Start"]];
    [self sendMessage];
}

- (void)tableCellLaufzeitChanged:(nonnull SwitcherTableCell *)switcherTableCell
{
    [self.smartGardenConfig updateGesamtlaufzeit];
    [self.tableView reloadData];
    self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
    self.smartGardenConfig.action = @"Uebertragen";
    [self sendMessage];
}

- (void)tableCellSwitchChanged:(nonnull SwitcherTableCell *)switcherTableCell
{
    if ([switcherTableCell.switchConfig.section intValue] == 1)
    {
        self.smartGardenConfig.action = @"Schalte";
        self.smartGardenConfig.control = [NSNumber numberWithInteger:switcherTableCell.tag];
        self.smartGardenConfig.state = switcherTableCell.switchConfig.aktiv;
        [self sendMessage];
    }
    else
    {
        [self.smartGardenConfig updateGesamtlaufzeit];
        [self.tableView reloadData];
        self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
        self.smartGardenConfig.action = @"Uebertragen";
        [self sendMessage];
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
        if (cell != nil && ![cell.switchConfig.modus isEqualToString:@"Vollzeit"])
        {
            if ([[switchInformation objectAtIndex:1] intValue] == 1)
            {
                self.smartGardenConfig.action = @"Status";
                [self sendMessage];
                [cell startLaufzeit];
                for (SwitcherTableCell *switchCell in [self cellForSwitchModus:@"Vollzeit"])
                {
                    [switchCell startLaufzeit];
                }
            }
            else
            {
                [cell stopLaufzeit];
                for (SwitcherTableCell *switchCell in [self cellForSwitchModus:@"Vollzeit"])
                {
                    [switchCell stopLaufzeit];
                }
            }
        }
    }
    switchInformation = [[[notification userInfo] objectForKey:@"Intervall"] componentsSeparatedByString:@" "];
    if (switchInformation != nil)
    {
        if ([[switchInformation objectAtIndex:1] intValue] == 1)
        {
            self.smartGardenConfig.action = @"Status";
            [self sendMessage];
        }
    }
    self.smartGardenConfig.badge = [[[notification userInfo] objectForKey:@"aps"] objectForKey:@"badge"];
    [self.nachrichtenButton setTitle:[NSString stringWithFormat:@"Nachrichten (%i)",[self.smartGardenConfig.badge intValue]]];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Nachrichten"])
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        self.smartGardenConfig.badge = [NSNumber numberWithInt:0];
        self.smartGardenConfig.pushnotificationId = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).token;
        self.smartGardenConfig.action = @"Uebertragen";
        [self sendMessage];
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
