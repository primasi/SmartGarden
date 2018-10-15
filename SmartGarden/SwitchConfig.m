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

@implementation SwitchConfig

- (NSString *)classToJson
{
    return [NSString stringWithFormat:@"{nummer:%@,aktiv:%@,modus:%@,gesamtlaufzeit:%@,aktuellelaufzeit:%@,section:%@,url:%@}",self.nummer,toBoolString(self.aktiv),self.modus,self.gesamtlaufzeit,self.aktuellelaufzeit,self.section,self.url];
}

- (SwitchConfig *) initWithJSON:(NSDictionary *) json
{
    for (NSString *subkey in json)
    {
        [self setValue:[json valueForKey:subkey] forKey:subkey];
    }
    return self;
}
/*
- (NSDictionary *) dictionaryWithPropertiesOfObject:(id)obj
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        [dict setObject:[obj valueForKey:key] forKey:key];
    }
    
    free(properties);
    
    return [NSDictionary dictionaryWithDictionary:dict];
}
*/
@end
