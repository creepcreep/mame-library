//
//  NSString_MLAdditions.m
//  MAME Library
//
//  Created by Johnnie Walker on 21/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSString_MLExtensions.h"

@implementation NSString (MLExtensions)

- (NSString *)stringByStripingLeadingThe {
	if ([self length] > 4 && [[[self substringToIndex:4] lowercaseString] isEqualToString:@"the "]) {
		return [self substringFromIndex:4];
	}
	
//	NSLog(@"stringByStripingLeadingThe: %@",self);
	
	return self;
}

- (NSComparisonResult)compareLikeiTunes:(NSString *)otherString;
{
//	NSLog(@"compareLikeiTunes: %@ to %@",self,otherString);

	NSString *ourName = [self stringByStripingLeadingThe];
	NSString *otherName = [otherString stringByStripingLeadingThe];
	
	if (ourName != nil && otherName != nil) {
		return [ourName caseInsensitiveCompare:otherName];
	} else if (ourName == nil && otherName == nil) {
		return NSOrderedSame;
	} else if (ourName == nil) {
		return NSOrderedAscending;
	}

	return NSOrderedDescending;
}

@end
