//  NSTreeController-DMExtensions.h
//  Library
//
//  Created by William Shipley on 3/10/06.
//  Copyright 2006 Delicious Monster Software, LLC. Some rights reserved,
//    see Creative Commons license on wilshipley.com

#import <Cocoa/Cocoa.h>

@interface NSTreeController (DMExtensions)
- (void)setSelectedObjects:(NSArray *)newSelectedObjects;
- (NSIndexPath *)indexPathToObject:(id)object;
@end

//  NSTreeController-DMExtensions.m
//  Library
//
//  Created by William Shipley on 3/10/06.
//  Copyright 2006 Delicious Monster Software, LLC. Some rights reserved,
//    see Creative Commons license on wilshipley.com

#import "NSTreeController-DMExtensions.h"

@interface NSTreeController (DMExtensions_Private)
- (NSIndexPath *)_indexPathFromIndexPath:(NSIndexPath *)baseIndexPath inChildren:(NSArray *)children
    childCount:(unsigned int)childCount toObject:(id)object;
@end