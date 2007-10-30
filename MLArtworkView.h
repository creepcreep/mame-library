//
//  MLArtworkView.h
//  MAME Library
//
//  Created by Johnnie Walker on 26/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MLArtworkWindowController;
@interface MLArtworkView : NSImageView {
	IBOutlet NSArrayController *availableGamesController;

	NSDictionary *_attributes;
	NSString *_title;
	NSSize _textSize;
	
	NSMutableArray *_artworkWindowControllers;
}
- (void)setTitle:(NSString *)title;
- (void)willCloseWindowOfController:(MLArtworkWindowController *)controller;
@end
