//
//  DBSourceSplitView.m
//
//  Created by Dave Batton, August 2006.
//  http://www.Mere-Mortal-Software.com/
//
//  Copyright 2006 by Dave Batton. Some rights reserved.
//  http://creativecommons.org/licenses/by/2.5/
//
//  This class subclasses KFSplitView from Ken Ferry so that the vertical splitter next to the source list remembers where it was last left, and also sets the splitter thickness to 1 pixel and draws it as a solid gray line. It also constrains the minimum sizes for both the source list and the right side of the splitter.
//


#define MIN_LEFT_VIEW_WIDTH 100
#define MIN_RIGHT_VIEW_WIDTH 695

#import "DBSourceSplitView.h"


@implementation DBSourceSplitView

-(void)awakeFromNib
{
	[super awakeFromNib];
	[self setDelegate:self];
	leftSubview = [[self subviews] objectAtIndex:0];
	rightSubview = [[self subviews] objectAtIndex:1];
}




- (CGFloat)dividerThickness
{
	return 1.0;
}




- (void)drawDividerInRect:(NSRect)aRect
{
//	[[NSColor redColor] set];
//	NSRectFill (aRect);
//
//	NSLog(@"drawDividerInRect");

	aRect.size.height -= 34;

	[[NSColor grayColor] set];
	NSRectFill (aRect);
}




- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	return (proposedMin + MIN_LEFT_VIEW_WIDTH);
}




- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{
	return (proposedMax - MIN_RIGHT_VIEW_WIDTH);
}




- (void)splitView:(id)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	float newHeight = [sender frame].size.height;
	float newWidth = [sender frame].size.width - [leftSubview frame].size.width - [self dividerThickness];

	NSRect newFrame = [leftSubview frame];
	newFrame.size.height = newHeight;
	[leftSubview setFrame:newFrame];

	newFrame = [rightSubview frame];
	newFrame.size.width = newWidth;
	newFrame.size.height = newHeight;
	[rightSubview setFrame:newFrame];
	
	[sender adjustSubviews];
	
	[[self window] setMinSize:NSMakeSize([leftSubview frame].size.width+MIN_RIGHT_VIEW_WIDTH+[self dividerThickness],[[self window] minSize].height)];
}


@end
