//
//  StartzeitenViewController.m
//  SmartGarden
//
//  Created by Primas, Ingo on 06.07.18.
//  Copyright © 2018 Bausparkasse Mainz AG. All rights reserved.
//

#import "StartzeitenViewController.h"

@interface StartzeitenViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) UITextField *inputField;
@property (strong, nonatomic) NSMutableArray *pickerData;
@property (strong, nonatomic) Startzeit *pickerValue;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;

- (IBAction)addButtonPressed:(id)sender;
- (IBAction)deleteButtonPressed:(id)sender;

@end

@implementation StartzeitenViewController

int pickerComponentWidth[3] = {130,70,70};

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pickerData = [[NSMutableArray alloc] init];
    NSMutableArray *pickerWeekdays = [[NSMutableArray alloc] init];
    for (int z = 0;z < 20;z++)
    {
        [pickerWeekdays addObjectsFromArray:[[NSMutableArray alloc] initWithObjects:@"Sonntag", @"Montag", @"Dienstag", @"Mittwoch", @"Donnerstag", @"Freitag", @"Samstag", nil]];
    }
    [self.pickerData insertObject:pickerWeekdays atIndex:0];
    NSMutableArray *pickerHours = [[NSMutableArray alloc] init];
    for (int z = 0;z < 20;z++)
    {
        for (int hours = 0;hours < 24;hours++)
        {
            [pickerHours addObject:[NSString stringWithFormat:@"%02i",hours]];
        }
    }
    [self.pickerData insertObject:pickerHours atIndex:1];
    NSMutableArray *pickerMinutes = [[NSMutableArray alloc] init];
    for (int z = 0;z < 20;z++)
    {
        for (int minutes = 0;minutes < 60;minutes++)
        {
            [pickerMinutes addObject:[NSString stringWithFormat:@"%02i",minutes]];
        }
    }
    [self.pickerData insertObject:pickerMinutes atIndex:2];
    
    self.pickerValue = [[Startzeit alloc] init];
    self.pickerValue.wochentag = [NSNumber numberWithInteger:0];
    self.pickerValue.stunde = [NSNumber numberWithInteger:0];
    self.pickerValue.minute = [NSNumber numberWithInteger:0];
    
    self.inputField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.inputField];
    
    UIPickerView *startzeitPicker = [[UIPickerView alloc] init];
    startzeitPicker.delegate = self;
    startzeitPicker.dataSource = self;
    [startzeitPicker selectRow:70 inComponent:0 animated:NO];
    [startzeitPicker selectRow:240 inComponent:1 animated:NO];
    [startzeitPicker selectRow:600 inComponent:2 animated:NO];
    
    [self.inputField setInputView:startzeitPicker];
    UIToolbar *startzeitPickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [startzeitPickerToolbar setTintColor:[UIColor grayColor]];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc]initWithTitle:@"Fertig" style:UIBarButtonItemStylePlain target:nil action:@selector(addPickerItem)];
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc]initWithTitle:@"Abbrechen" style:UIBarButtonItemStylePlain target:nil action:@selector(cancelPickerItem)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [startzeitPickerToolbar setItems:[NSArray arrayWithObjects:cancelBtn, space, doneBtn, nil]];
    [self.inputField setInputAccessoryView:startzeitPickerToolbar];
}

- (void)addPickerItem
{
    [self.inputField resignFirstResponder];
    Startzeit *startzeit = [[Startzeit alloc] init];
    startzeit.wochentag = [NSNumber numberWithInt:[self.pickerValue.wochentag intValue] % 7];
    startzeit.stunde = [NSNumber numberWithInt:[self.pickerValue.stunde intValue] % 24];
    startzeit.minute = [NSNumber numberWithInt:[self.pickerValue.minute intValue] % 60];
    [self.smartGardenConfig.startzeiten addObject:startzeit];
    //self.pickerValue = [[Startzeit alloc] init];
    
    self.deleteButton.enabled = true;
    [self.tableView reloadData];
}

- (void)cancelPickerItem
{
    [self.inputField resignFirstResponder];
    self.deleteButton.enabled = true;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.smartGardenConfig.startzeiten count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StartzeitenTableCell" forIndexPath:indexPath];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"StartzeitenTableCell"];
    }
    
    Startzeit *startzeit = self.smartGardenConfig.startzeiten[indexPath.row];
    NSMutableArray *data = self.pickerData[0];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %02i:%02i Uhr",data[[startzeit.wochentag intValue]],[startzeit.stunde intValue],[startzeit.minute intValue]];
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",[[self.pickerData objectAtIndex:0] objectAtIndex:[startzeit.wochentag intValue]]]];
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self.smartGardenConfig.startzeiten removeObjectAtIndex:indexPath.row];
        if ([self.smartGardenConfig.startzeiten count] == 0)
        {
            self.addButton.enabled = YES;
            [self.tableView setEditing:NO animated:YES];
        }
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert)
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (IBAction)addButtonPressed:(id)sender
{
    [self.inputField becomeFirstResponder];
    self.deleteButton.enabled = NO;
}

- (IBAction)deleteButtonPressed:(id)sender
{
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    self.addButton.enabled = !self.addButton.enabled;
}

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView
{
    return [self.pickerData count];
}

- (CGFloat)pickerView:(nonnull UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return pickerComponentWidth[component];
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
            self.pickerValue.wochentag = [NSNumber numberWithInteger:row];
            break;
        case 1:
            self.pickerValue.stunde = [NSNumber numberWithInteger:row];
            break;
        case 2:
            self.pickerValue.minute = [NSNumber numberWithInteger:row];
            break;
    }
}

@end
