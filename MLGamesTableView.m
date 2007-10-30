//
//  MLGamesTableView.m
//  MAME Library
//
//  Created by Johnnie Walker on 06/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLGamesTableView.h"


@implementation MLGamesTableView

// CHANGED (added new method)
 - (NSMenu *) menuForEvent: (NSEvent *) event;
{
    NSPoint mousePoint = [self convertPoint:[event locationInWindow] fromView:nil];
	unsigned clickedIndex = [self rowAtPoint:mousePoint];		

	NSArray *games = [availableGamesArrayController arrangedObjects];
	
	if (clickedIndex < [games count]) {
		//NSLog(@"menuForGame: %@",[games objectAtIndex:clickedIndex]);
		if ([[games objectAtIndex:clickedIndex] respondsToSelector:@selector(menuForEvent:)]) {
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:clickedIndex] byExtendingSelection:NO];

			return [[games objectAtIndex:clickedIndex] menuForEvent:event];
		}
	}

    return [super menuForEvent:event];
}

@end
