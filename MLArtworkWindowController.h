//
//  MLArtworkWindowController.h
//  MAME Library
//
//  Created by Johnnie Walker on 26/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MLArtworkWindowController : NSWindowController {
	IBOutlet NSImageView *_artworkView;
	
	NSString *_title;
	NSImage *_image;
	
	id _parent;
	
}

@end
