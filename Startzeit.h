//
//  Startzeit.h
//  SmartGarden
//
//  Created by Primas, Ingo on 17.07.18.
//  Copyright © 2018 Bausparkasse Mainz AG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Startzeit : NSObject

@property (nonatomic, strong) NSNumber * wochentag;
@property (nonatomic, strong) NSNumber * stunde;
@property (nonatomic, strong) NSNumber * minute;

- (NSString *)classToJson;
- (Startzeit *) initWithJSON:(NSDictionary *) json;

@end
