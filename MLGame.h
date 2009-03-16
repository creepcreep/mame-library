//
//  MLGame.h
//  MAME Library
//
//  Created by Johnnie Walker on 18/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

@interface MLGame : NSManagedObject {
	NSImage *_photo;
	NSImage *_overlayImage;	
	
	NSMenu *_contextMenu;
}
- (BOOL)searchForScreenShot;
- (BOOL)searchForROM;
- (IBAction)revealInFinder:(id)sender;
- (void)applyUserGameInfo:(NSDictionary *)userGameInfo;
- (NSDictionary *)userGameInfo;
- (NSData *)pasteboardData;
- (NSImage *)photo;

- (NSDictionary *)metadataDictionary;
- (NSString *)metadataPath;
- (void)saveMetadata;
- (void)deleteMetadata;
@end
