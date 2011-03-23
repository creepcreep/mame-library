//
//  MLSourceListSplitView.m
//  MAME Library
//
//  Created by Johnnie Walker on 24/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLSourceListSplitView.h"

#define MIN_TOP_VIEW_HEIGHT 200
#define MIN_BOTTOM_VIEW_HEIGHT 100

@implementation MLSourceListSplitView

-(void)awakeFromNib
{
	[super awakeFromNib];
	[self setDelegate:self];
	topSubview = [[self subviews] objectAtIndex:0];
	bottomSubview = [[self subviews] objectAtIndex:1];
}


- (CGFloat)dividerThickness
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MLHideArtworkView"]) {
		return 0.0;
	}
	return 1.0;
}

- (void)drawDividerInRect:(NSRect)aRect
{
//	[[NSColor redColor] set];
//	NSRectFill (aRect);
//
//	NSLog(@"drawDividerInRect");

	//aRect.size.height -= 34;

	[[NSColor grayColor] set];
	NSRectFill (aRect);
}


- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	return (proposedMin + MIN_TOP_VIEW_HEIGHT);
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{
	return (proposedMax - MIN_BOTTOM_VIEW_HEIGHT);
}

- (void)splitView:(id)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	float newTopHeight = [sender frame].size.height - [bottomSubview frame].size.height - [self dividerThickness];
//	float newBottomHeight = [sender frame].size.height - [bottomSubview frame].size.height - [self dividerThickness];

	NSRect newFrame = [topSubview frame];
	newFrame.size.width = [sender frame].size.width;
	newFrame.size.height = newTopHeight;
	[topSubview setFrame:newFrame];

	newFrame = [bottomSubview frame];
	newFrame.size.width = [sender frame].size.width;
	[bottomSubview setFrame:newFrame];
	
	[sender adjustSubviews];
	
	[[self window] setMinSize:NSMakeSize([[self window] minSize].width,[topSubview frame].size.height+MIN_BOTTOM_VIEW_HEIGHT+[self dividerThickness])];
}


@end
