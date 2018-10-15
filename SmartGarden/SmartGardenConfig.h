//
//  SmartGardenConfig.h
//  
//
//  Created by Primas, Ingo on 16.10.13.
//  Copyright (c) 2013 Bausparkasse Mainz AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SwitchConfig.h"
#import "Startzeit.h"

@interface SmartGardenConfig : NSObject

@property (nonatomic, strong) NSNumber * automatikAktiviert;
@property (nonatomic, strong) NSNumber * badge;
@property (nonatomic, strong) NSString * pushnotificationId;
@property (nonatomic, strong) NSString * serverzeit;
@property (nonatomic, strong) NSMutableDictionary * switches;
@property (nonatomic, strong) NSMutableArray * startzeiten;
@property (nonatomic, strong) NSMutableArray * devices;

- (void)initWithJSON:(NSDictionary *) json;
- (NSString *) classToJson;
- (void)updateGesamtlaufzeit;
- (NSMutableArray *)switchesForSection:(int)section;
- (SwitchConfig *)switchForIndexPath:(NSIndexPath *)indexPath;
- (SwitchConfig *)nextActiveSwitchConfig:(SwitchConfig *)activeSwitchConfig;

@end
