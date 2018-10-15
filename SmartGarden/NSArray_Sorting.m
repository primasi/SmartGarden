
//
//  NSSet_Sorting.m
//
//  Created by Ingo Primas on 07.05.13.
//  Copyright (c) 2013 Bausparkasse Mainz AG. All rights reserved.
//

#import "NSArray_Sorting.h"

@implementation NSArray (Sorting)

- (NSArray *)sortAscending:(NSString *) sortkey
{
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortkey ascending:YES];
    return [self sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

- (NSArray *)sortDescending:(NSString *) sortkey
{
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortkey ascending:NO];
    return [self sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

- (NSArray *)sortArrayDescending:(NSArray *) sortkeys
{
    NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
    for (int z = 0;z < sortkeys.count;z++)
    {
        [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:[sortkeys objectAtIndex:z]  ascending:NO]];
    }
    return [self sortedArrayUsingDescriptors:sortDescriptors];
}

@end
