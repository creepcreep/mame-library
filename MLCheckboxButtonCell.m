//
//  MLCheckboxButtonCell.m
//  MAME Library
//
//  Created by Johnnie Walker on 05/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLCheckboxButtonCell.h"


@implementation MLCheckboxButtonCell

- (void)drawImage:(NSImage*)image withFrame:(NSRect)frame inView:(NSView*)controlView
{
	if([self showsStateBy] == NSNoCellMask){
		[super drawImage:image withFrame:frame inView:controlView];
		return;
	}
	
	NSString *state = [self isEnabled] ? ([self isHighlighted] ? @"-P" : @"-N") : @"-D";
	NSString *position = [self intValue] ? @"On" : @"Off";
	NSImage *checkImage = [NSImage imageNamed:[NSString stringWithFormat:@"tools-checkbox%@%@.tiff", position, state]];
	
	NSSize size = [checkImage size];
	float addX = 2;
	float y = NSMaxY(frame) - (frame.size.height-size.height)/2.0;
	float x = frame.origin.x+addX;
	
	[checkImage compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];
}

@end
