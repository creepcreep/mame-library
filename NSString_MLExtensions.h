//
//  NSString_MLExtensions.h
//  MAME Library
//
//  Created by Johnnie Walker on 21/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (MLExtensions) 
- (NSString *)stringByStripingLeadingThe;
- (NSComparisonResult)compareLikeiTunes:(NSString *)otherString;
@end
