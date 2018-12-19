//
//  SmartGardenConfig.m
//  SmartGarden
//
//  Created by Primas, Ingo on 29.11.17.
//  Copyright © 2017 Bausparkasse Mainz AG. All rights reserved.
//

#import <objc/runtime.h>

#import "SmartGardenConfig.h"
#import "NSArray_Sorting.h"

#define toBoolString(aBool) ([aBool boolValue] ? @"true" : @"false")

@implementation SmartGardenConfig

- (id) init
{
    self = [super init];
    if (self)
    {
        self.control = [NSNumber numberWithInt:0];
        self.state = false;
        self.badge = [NSNumber numberWithInt:0];
        self.pushnotificationId = nil;
    }
    return self;
}

- (void) initWithJSON:(NSDictionary *) json
{
    for (NSString *key in [json allKeys])
    {
        if ([key isEqualToString:@"switches"])
        {
            self.switches = [[NSMutableDictionary alloc] init];
            NSArray *jsonArray = [json valueForKey:key];
            for (NSDictionary *subjson in jsonArray)
            {
                SwitchConfig *switchConfig = [[SwitchConfig alloc] initWithJSON:subjson];
                [self.switches setObject:switchConfig forKey:switchConfig.nummer];
            }
        }
        else if ([key isEqualToString:@"startzeiten"])
        {
            self.startzeiten = [[NSMutableArray alloc] init];
            NSArray *jsonArray = [json valueForKey:key];
            for (NSDictionary *subjson in jsonArray)
            {
                Startzeit *startzeit = [[Startzeit alloc] initWithJSON:subjson];
                [self.startzeiten addObject:startzeit];
            }
        }
        else if ([key isEqualToString:@"devices"])
        {
            self.devices = [[NSMutableArray alloc] init];
            NSArray *jsonArray = [json valueForKey:key];
            for (NSString *subjson in jsonArray)
            {
                [self.devices addObject:subjson];
            }
        }
        else
        {
            [self setValue:[json valueForKey:key] forKey:key];
        }
    }
}

- (NSString *)classToJson
{
    NSString *subAttributesSwitches = @"[";
    for (SwitchConfig *switchConfig in [[self.switches allValues] sortAscending:@"nummer"])
    {
        if (![subAttributesSwitches isEqualToString:@"["])
        {
            subAttributesSwitches = [subAttributesSwitches stringByAppendingString:@","];
        }
        subAttributesSwitches = [subAttributesSwitches stringByAppendingString:[switchConfig classToJson]];
    }
    subAttributesSwitches = [subAttributesSwitches stringByAppendingString:@"]"];
    
    NSString *subAttributesStartzeiten = @"[";
    for (Startzeit *startzeit in self.startzeiten)
    {
        if (![subAttributesStartzeiten isEqualToString:@"["])
        {
            subAttributesStartzeiten = [subAttributesStartzeiten stringByAppendingString:@","];
        }
        subAttributesStartzeiten = [subAttributesStartzeiten stringByAppendingString:[startzeit classToJson]];
    }
    subAttributesStartzeiten = [subAttributesStartzeiten stringByAppendingString:@"]"];
    
    NSString *subAttributesDevices = @"[";
    for (NSString *device in self.devices)
    {
        if (![subAttributesDevices isEqualToString:@"["])
        {
            subAttributesDevices = [subAttributesDevices stringByAppendingString:@","];
        }
        subAttributesDevices = [subAttributesDevices stringByAppendingString:device];
    }
    subAttributesDevices = [subAttributesDevices stringByAppendingString:@"]"];
    
    NSString *attributes = [NSString stringWithFormat:@"{action:%@,control:%@,state:%@,automatikAktiviert:%@,badge:%@,pushnotificationId:%@,switches:%@,startzeiten:%@}",                          self.action,self.control,toBoolString(self.state),toBoolString(self.automatikAktiviert),self.badge,self.pushnotificationId,subAttributesSwitches,subAttributesStartzeiten];

    return attributes;
}

- (void)updateGesamtlaufzeit
{
    int laufzeit = 0;
    for (SwitchConfig *switchConfig in [self switchesForSection:1])
    {
        if ([switchConfig.modus isEqualToString:@"Teilzeit"])
        {
            laufzeit += ([switchConfig.gesamtlaufzeit intValue]);
        }
    }
    for (SwitchConfig *switchConfig in [self switchesForSection:1])
    {
        if ([switchConfig.modus isEqualToString:@"Vollzeit"])
        {
            switchConfig.gesamtlaufzeit = [NSNumber numberWithInt:laufzeit];
        }
    }
}

- (NSMutableArray *)switchesForSection:(int)section
{
    NSMutableArray *switchesForSection = [[NSMutableArray alloc] init];
    for (SwitchConfig *switchConfig in [self.switches allValues])
    {
        if ([switchConfig.section intValue] == section)
        {
            [switchesForSection addObject:switchConfig];
        }
    }
    return switchesForSection;
}

- (SwitchConfig *)switchForIndexPath:(NSIndexPath *)indexPath
{
    SwitchConfig *switchForIndexPath = nil;
    
    int switchConfigCount = 0;
    for (SwitchConfig *switchConfig in [[self.switches allValues] sortAscending:@"nummer"])
    {
        if ([switchConfig.section isEqualToNumber:[NSNumber numberWithInteger:indexPath.section]])
        {
            if (switchConfigCount == indexPath.row)
            {
                switchForIndexPath = switchConfig;
                break;
            }
            else
            {
                switchConfigCount++;
            }
        }
    }
    return switchForIndexPath;
}

- (SwitchConfig *)nextActiveSwitchConfig:(SwitchConfig *)activeSwitchConfig
{
    SwitchConfig *switchForSwitchConfig = nil;
    
    for (SwitchConfig *switchConfig in [[self.switches allValues] sortAscending:@"nummer"])
    {
        if (activeSwitchConfig == nil)
        {
            if ([switchConfig.section intValue] == 1 && [switchConfig.modus isEqualToString:@"Teilzeit"])
            {
                switchForSwitchConfig = switchConfig;
                break;
            }
        }
        else
        {
            if (switchConfig.nummer > activeSwitchConfig.nummer)
            {
                if ([switchConfig.section intValue] == 1 && [switchConfig.modus isEqualToString:@"Teilzeit"])
                {
                    switchForSwitchConfig = switchConfig;
                    break;
                }
            }
        }
    }
    return switchForSwitchConfig;
}

@end
