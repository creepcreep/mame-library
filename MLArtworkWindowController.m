//
//  MLArtworkWindowController.m
//  MAME Library
//
//  Created by Johnnie Walker on 26/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLArtworkWindowController.h"
#import "MLArtworkView.h"

@implementation MLArtworkWindowController

- (void)windowWillClose:(NSNotification *)aNotification
{
	[(MLArtworkView *)[self valueForKey:@"parent"] willCloseWindowOfController:self];
}

- (void)setImage:(NSImage *)image
{	
	NSImage *oldImage = _image;

	[self willChangeValueForKey:@"image"];
	_image = [image retain];
	[self didChangeValueForKey:@"image"];	
	
	[oldImage release];	
	oldImage = nil;

	NSWindow *window = [self window];

	if (nil != _image) {
		NSRect windowRect = [window contentRectForFrameRect:[window frame]];
		windowRect.size.width = [_image size].width;
		windowRect.size.height = [_image size].height;
		[[self window] setFrame:[window frameRectForContentRect:windowRect] display:NO];
	}
}

@end
