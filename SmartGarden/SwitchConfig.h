//
//  SwitchConfig.h
//  SmartGarden
//
//  Created by Primas, Ingo on 29.11.17.
//  Copyright © 2017 Bausparkasse Mainz AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SwitchConfig : NSObject

@property (nonatomic, strong) NSNumber * aktiv;
@property (nonatomic, strong) NSString * modus;
@property (nonatomic, strong) NSNumber * nummer;
@property (nonatomic, strong) NSNumber * gesamtlaufzeit;
@property (nonatomic, strong) NSNumber * aktuellelaufzeit;
@property (nonatomic, strong) NSNumber * section;
@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) NSString * name;

- (NSString *)classToJson;
- (SwitchConfig *) initWithJSON:(NSDictionary *) json;

@end
