//
//  MLSlider.m
//  MAME Library
//
//  Created by Johnnie Walker on 18/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLSlider.h"
#import "MLSliderCell.h"

@implementation MLSlider
 
static Class cellClass; 
 
+ (void) initialize { 
    if (self == [MLSlider class]) 
    { 
        // Initial version 
        [self setVersion: 1]; 
        [self setCellClass: [MLSliderCell class]]; 
    } 
} 
 
+ (void) setCellClass: (Class)class { 
    cellClass = class; 
} 
 
+ (Class) cellClass { 
    return cellClass; 
} 

@end
