//
//  MLOutlineView.m
//  MAME Library
//
//  Created by Johnnie Walker on 18/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLOutlineView.h"
#import "MLOutlineViewDragController.h"

@implementation MLOutlineView

- (void)textDidEndEditing:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
	
    int textMovement = [[userInfo valueForKey:@"NSTextMovement"] intValue];

    if (textMovement == NSReturnTextMovement
			|| textMovement == NSTabTextMovement
			|| textMovement == NSBacktabTextMovement) {

        NSMutableDictionary *newInfo;
        newInfo = [NSMutableDictionary dictionaryWithDictionary: userInfo];

        [newInfo setObject:[NSNumber numberWithInt: NSIllegalTextMovement]
					forKey:@"NSTextMovement"];

        notification = [NSNotification notificationWithName:[notification name]
													 object:[notification object]
												   userInfo:newInfo];

    }

    [super textDidEndEditing: notification];
    [[self window] makeFirstResponder:self];

}

- (void)keyDown:(NSEvent*)theEvent {
    if ([[theEvent characters] isEqualToString: @"\177"]) {
		[(MLOutlineViewDragController *)[self delegate] delete:self];
    } else {
        [super keyDown: theEvent];
    }
}

-(IBAction)delete:(id)sender
{
	[(MLOutlineViewDragController *)[self delegate] delete:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{
    if ([aMenuItem action] == @selector(delete:)) {
		return [(MLOutlineViewDragController *)[self delegate] canRemove];
    }
	
    return YES;
}

- (void)drawRect:(NSRect)aRect
{
	[super drawRect:aRect];
	
	if ([[self valueForKey:@"redrawWhenComplete"] boolValue]){
		//NSLog(@"redrawWhenComplete");
		[self setValue:[NSNumber numberWithBool:NO] forKey:@"redrawWhenComplete"];
		[self display];
	}
}

@end
