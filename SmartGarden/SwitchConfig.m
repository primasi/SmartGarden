//
//  SwitchConfig.m
//  SmartGarden
//
//  Created by Primas, Ingo on 29.11.17.
//  Copyright © 2017 Bausparkasse Mainz AG. All rights reserved.
//

#import <objc/runtime.h>

#import "SwitchConfig.h"

#define toBoolString(aBool) ([aBool boolValue] ? @"true" : @"false")
#define valueOrNil(aValue) ([aValue isKindOfClass:[NSString class]] ? ([aValue isEqualToString:@"(null)"] ? nil : aValue) : aValue)

@implementation SwitchConfig

- (NSString *)classToJson
{
    return [NSString stringWithFormat:@"{nummer:%@,aktiv:%@,modus:%@,gesamtlaufzeit:%@,aktuellelaufzeit:%@,section:%@,url:%@}",self.nummer,toBoolString(self.aktiv),self.modus,self.gesamtlaufzeit,self.aktuellelaufzeit,self.section,self.url];
}

- (SwitchConfig *) initWithJSON:(NSDictionary *) json
{
    for (NSString *subkey in json)
    {
        [self setValue:valueOrNil([json valueForKey:subkey]) forKey:subkey];
    }
    return self;
}

@end
