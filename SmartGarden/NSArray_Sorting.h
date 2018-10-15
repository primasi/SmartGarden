//
//  NSArray_Sorting.h
//  BKM App 2
//
//  Created by Primas, Ingo on 16.01.14.
//  Copyright (c) 2014 Bausparkasse Mainz AG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Sorting)

- (NSArray *)sortAscending:(NSString *) sortkey;
- (NSArray *)sortDescending:(NSString *) sortkey;
- (NSArray *)sortArrayDescending:(NSArray *) sortkeys;

@end
