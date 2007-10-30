//
//  MLMatrix.m
//  MAME Library
//
//  Created by Johnnie Walker on 23/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLMatrix.h"
#import "MLHeaderViewButtonCell.h"

@implementation MLMatrix

static Class cellClass; 
 
+ (void) initialize { 
    if (self == [MLMatrix class]) 
    { 
        // Initial version 
        [self setVersion: 1]; 
        [self setCellClass: [MLHeaderViewButtonCell class]]; 
    } 
} 
 
+ (void) setCellClass: (Class)class { 
    cellClass = class; 
} 
 
+ (Class) cellClass { 
    return cellClass; 
} 

@end
