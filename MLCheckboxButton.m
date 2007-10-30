//
//  MLCheckboxButton.m
//  MAME Library
//
//  Created by Johnnie Walker on 05/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLCheckboxButton.h"
#import "MLCheckboxButtonCell.h"

@implementation MLCheckboxButton

+ (Class)cellClass
{
	return [MLCheckboxButtonCell class];
}

@end
