//
//  MLArtworkView.m
//  MAME Library
//
//  Created by Johnnie Walker on 26/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLArtworkView.h"
#import "MLArtworkWindowController.h"

@implementation MLArtworkView

- (void)awakeFromNib
{
	[availableGamesController addObserver:self forKeyPath:@"selection" options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == availableGamesController) {
		int count = [[availableGamesController selectedObjects] count];
		if (count == 0) {
			[self setTitle:@"Nothing\nSelected"];
		} else if (count > 1) {
			[self setTitle:@"Multiple\nSelected"];
		}
	}
}

- (void)setTitle:(NSString *)title
{

	NSString *oldTitle = _title;
	_title = [title retain];
	[oldTitle release];

	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[style setAlignment:NSCenterTextAlignment];
	
	NSFont *font = [NSFont systemFontOfSize:16.0];
	
	NSDictionary *oldAttributes = _attributes;										
	_attributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSColor lightGrayColor],NSForegroundColorAttributeName,style,NSParagraphStyleAttributeName,font,NSFontAttributeName,nil] retain];		
	[oldAttributes release];

	_textSize = [_title sizeWithAttributes:_attributes];

	[self setNeedsDisplay:YES];	
}

- (void) dealloc {

	[_attributes release];
	[_title release];
	[_artworkWindowControllers release];

	[super dealloc];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if (nil != [self image]) {			
		// open a viewer
		if (nil == _artworkWindowControllers) {
			_artworkWindowControllers = [[NSMutableArray alloc] initWithCapacity:1];
		}
		
		MLArtworkWindowController *windowController = [[[MLArtworkWindowController alloc] initWithWindowNibName:@"Artwork Viewer"] autorelease];

		[windowController setValue:self forKey:@"parent"];
		[windowController setValue:[self image] forKey:@"image"];
		[windowController setValue:[availableGamesController valueForKeyPath:@"selection.desc"] forKey:@"title"];		
		[windowController showWindow:self];

		[_artworkWindowControllers addObject:windowController];
	}
}

- (void)willCloseWindowOfController:(MLArtworkWindowController *)controller
{
	[_artworkWindowControllers removeObject:controller];
}

- (void)drawRect:(NSRect)aRect
{
	[[NSColor whiteColor] set];
	NSRectFill(aRect);
	
	[self resetCursorRects];

	if (nil == [self image]) {			
		
		NSRect textDrawingRect = NSMakeRect(aRect.origin.x + ((aRect.size.width - _textSize.width)/2),
											aRect.origin.y + ((aRect.size.height - _textSize.height)/2),
											_textSize.width,
											_textSize.height
											);
														
		[_title drawInRect:textDrawingRect withAttributes:_attributes];
		
		return;
	}
	
	[self addCursorRect:[self frame] cursor:[NSCursor pointingHandCursor]];
	[super drawRect:aRect];
}

@end
