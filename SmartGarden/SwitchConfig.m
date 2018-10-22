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

@synthesize gesamtlaufzeit = _gesamtlaufzeit;
@synthesize aktuellelaufzeit = _aktuellelaufzeit;
@synthesize url = _url;

- (NSString *)classToJson
{
    NSString *toJson = [NSString stringWithFormat:@"{nummer:%@,aktiv:%@,modus:%@,gesamtlaufzeit:%@,aktuellelaufzeit:%@,section:%@}",self.nummer,toBoolString(self.aktiv),self.modus,self.gesamtlaufzeit,self.aktuellelaufzeit,self.section];
    if (self.url != nil)
    {
        toJson = [NSString stringWithFormat:@"{nummer:%@,aktiv:%@,modus:%@,gesamtlaufzeit:%@,aktuellelaufzeit:%@,section:%@,url:%@}",self.nummer,toBoolString(self.aktiv),self.modus,self.gesamtlaufzeit,self.aktuellelaufzeit,self.section,self.url];
    }
    return toJson;
}

- (SwitchConfig *) initWithJSON:(NSDictionary *) json
{
    for (NSString *subkey in json)
    {
        [self setValue:valueOrNil([json valueForKey:subkey]) forKey:subkey];
    }
    return self;
}

- (NSNumber *) gesamtlaufzeit
{
    return [NSNumber numberWithInt:[_gesamtlaufzeit intValue] / 60];
}

- (void) setGesamtlaufzeit:(NSNumber *) gesamtlaufzeit
{
    _gesamtlaufzeit = [NSNumber numberWithInt:[gesamtlaufzeit intValue] * 60];
}

- (NSNumber *) aktuellelaufzeit
{
    return [NSNumber numberWithInt:[_aktuellelaufzeit intValue] / 60];
}

- (void) setAktuellelaufzeit:(NSNumber *) gesamtlaufzeit
{
    _aktuellelaufzeit = [NSNumber numberWithInt:[_aktuellelaufzeit intValue] * 60];
}

- (NSString *) url
{
    return _url == nil ? nil : [_url length] == 0 ? nil : _url;
}

- (void) setUrl:(NSString *) url
{
    _url = url;
}

@end
