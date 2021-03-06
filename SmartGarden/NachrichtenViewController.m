//
//  NachrichtenViewController.m
//  SmartGarden
//
//  Created by Primas, Ingo on 08.05.18.
//  Copyright © 2018 Bausparkasse Mainz AG. All rights reserved.
//

#import "NachrichtenViewController.h"
#import <UserNotifications/UserNotifications.h>

@interface NachrichtenViewController ()

@property (strong, nonatomic) NSMutableArray *notifications;
@property (strong, nonatomic) NSMutableArray *newnotifications;

- (IBAction)loeschenButtonPressed:(id)sender;

@end

@implementation NachrichtenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
  
    self.notifications = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"PushNotifications"]];
    self.newnotifications = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"NewPushNotifications"]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([self isMovingFromParentViewController])
    {
        for (NSDictionary *notification in self.newnotifications)
        {
            [self.notifications insertObject:notification atIndex:0];
        }
        [self.newnotifications removeAllObjects];
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.newnotifications] forKey:@"NewPushNotifications"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.notifications] forKey:@"PushNotifications"];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.notifications count] + [self.newnotifications count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NachrichtenTableCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"NachrichtenTableCell"];
    }
    
    NSDictionary *notification = nil;
    
    if (indexPath.row < [self.newnotifications count])
    {
        notification = [self.newnotifications objectAtIndex:indexPath.row];
        UIFontDescriptor *fontD = [cell.textLabel.font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        cell.textLabel.font = [UIFont fontWithDescriptor:fontD size:0];
    }
    else
    {
        notification = [self.notifications objectAtIndex:indexPath.row - [self.newnotifications count]];
        UIFontDescriptor *fontD = [cell.textLabel.font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorClassUnknown];
        cell.textLabel.font = [UIFont fontWithDescriptor:fontD size:0];
    }
    cell.textLabel.text = [[notification valueForKey:@"aps"] valueForKey:@"alert"];
    cell.detailTextLabel.text = [notification valueForKey:@"date"];
    
    return cell;
}

#pragma mark - Navigation

- (IBAction)loeschenButtonPressed:(id)sender
{
    [self.notifications removeAllObjects];
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.notifications] forKey:@"PushNotifications"];
    [self.tableView reloadData];
}

@end
