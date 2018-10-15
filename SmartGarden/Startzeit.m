//
//  Startzeit.m
//  SmartGarden
//
//  Created by Primas, Ingo on 17.07.18.
//  Copyright © 2018 Bausparkasse Mainz AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Startzeit.h"

@implementation Startzeit

- (NSString *)classToJson
{
    return [NSString stringWithFormat:@"{wochentag:%@,stunde:%@,minute:%@}",self.wochentag,self.stunde,self.minute];
}

- (Startzeit *) initWithJSON:(NSDictionary *) json
{
    for (NSString *subkey in json)
    {
        [self setValue:[json valueForKey:subkey] forKey:subkey];
    }
    return self;
}

@end
