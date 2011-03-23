//
//  MLGame.m
//  MAME Library
//
//  Created by Johnnie Walker on 18/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLGame.h"
#import "MAME_Library_AppDelegate.h"
#import "constants.h"

@implementation MLGame

- (void) dealloc {
	[_photo release];
	[_contextMenu release];
	[super dealloc];
}

- (NSImage *)photo
{
	if (nil != _photo) {
		return _photo;
	}
	
	if (nil == [self valueForKey:@"screenshotPath"] && ![self searchForScreenShot]) {
	
		// still nothing? are we a clone?
		if (nil != [self valueForKey:@"cloneof"] && ![[self valueForKey:@"cloneof"] isEqualToString:@""]) {	
			NSManagedObjectContext *context = [self managedObjectContext];
			NSPersistentStoreCoordinator *coordinator = [context persistentStoreCoordinator];
			NSManagedObjectModel *model = [coordinator managedObjectModel];
			NSFetchRequest *fetchRequest = [model fetchRequestFromTemplateWithName:@"gameWithName" substitutionVariables:[NSDictionary dictionaryWithObject:[self valueForKey:@"cloneof"] forKey:@"name"]];
			NSError *error;				
			MLGame *myClone;
			NSArray *games = [context executeFetchRequest:fetchRequest error:&error];				
			//NSLog(@"games: %@",games);
			if (([games count] > 0) && (myClone = [games objectAtIndex:0])) {
				//NSLog(@"%@ using screenshot from %@",[self valueForKey:@"name"],[myClone valueForKey:@"name"]);
				//NSLog(@"%@",[myClone photo]);
				_photo = [[myClone photo] retain];
				return _photo;
			}
		}	
	
		_photo = [[(MAME_Library_AppDelegate *)[NSApp delegate] valueForKey:@"missingImage"] retain];
		return _photo;
	}
	
	NSImage *overlayImage = [(MAME_Library_AppDelegate *)[NSApp delegate] valueForKey:@"overlayImage"];
		
	_photo = [[NSImage alloc] initWithContentsOfFile:[self valueForKey:@"screenshotPath"]];
	
	if (_photo) {
		//[_photo setFlipped:YES];
		[_photo lockFocus];
		[overlayImage drawInRect:NSMakeRect(0,0,[_photo size].width,[_photo size].height) fromRect:NSMakeRect(0,0,[overlayImage size].width,[overlayImage size].height) operation:NSCompositeSourceOver fraction:1.0];
		//[_photo setFlipped:NO];
		[_photo unlockFocus];							
	}	
	
	return _photo;		
}

- (void)setRating:(NSNumber *)rating
{
    [self willChangeValueForKey:@"rating"];
    [self setPrimitiveValue:[NSNumber numberWithFloat:round([rating floatValue])] forKey:@"rating"];
    [self didChangeValueForKey:@"rating"];
}

- (void)applyUserGameInfo:(NSDictionary *)userGameInfo
{
	if (nil != [userGameInfo valueForKey:@"rating"]) {
		[self setValue:[userGameInfo valueForKey:@"rating"] forKey:@"rating"];
	}
	if (nil != [userGameInfo valueForKey:@"lastplayed"]) {
		[self setValue:[userGameInfo valueForKey:@"lastplayed"] forKey:@"lastplayed"];
	}
	if (nil != [userGameInfo valueForKey:@"playcount"]) {
		[self setValue:[userGameInfo valueForKey:@"playcount"] forKey:@"playcount"];
	}
//	if (nil != [userGameInfo valueForKey:@"comments"]) {
//		[self setValue:[userGameInfo valueForKey:@"comments"] forKey:@"comments"];
//	}	
}

- (NSDictionary *)userGameInfo
{
	NSDictionary *gameUserInfo = [NSMutableDictionary dictionaryWithCapacity:3];
	[gameUserInfo setValue:[self valueForKey:@"name"] forKey:@"name"];
	if ([self valueForKey:@"rating"] != nil) {
		[gameUserInfo setValue:[self valueForKey:@"rating"] forKey:@"rating"];
	}
	if ([self valueForKey:@"lastplayed"] != nil) {
		[gameUserInfo setValue:[self valueForKey:@"lastplayed"] forKey:@"lastplayed"];
	}
	if ([self valueForKey:@"playcount"] != nil) {
		[gameUserInfo setValue:[self valueForKey:@"playcount"] forKey:@"playcount"];
	}
//	if ([nextGame valueForKey:@"comments"] != nil) {
//		[gameUserInfo setValue:[nextGame valueForKey:@"comments"] forKey:@"comments"];
//	}	
	
	return gameUserInfo;
}

- (NSData *)pasteboardData;
{
	return [NSArchiver archivedDataWithRootObject:[NSDictionary dictionaryWithObject:[self valueForKey:@"name"] forKey:@"name"]];
}

- (IBAction)revealInFinder:(id)sender
{	
	if (nil != [self valueForKey:@"romPath"]) {
		[[NSWorkspace sharedWorkspace] selectFile:[self valueForKey:@"romPath"] inFileViewerRootedAtPath:nil];	
	}
	
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
	if (nil != _contextMenu) {
		return _contextMenu;
	}
	
	_contextMenu = [[NSMenu alloc] initWithTitle:[self valueForKey:@"desc"]];
	
	NSMenuItem *item;

	item = [[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Play %@",[self valueForKey:@"desc"]] action:@selector(play) keyEquivalent:@""] autorelease];
//	[item setKeyEquivalentModifierMask:0];
	[item setTarget:self];	
	[_contextMenu addItem:item];

	[_contextMenu addItem:[NSMenuItem separatorItem]];

	item = [[[NSMenuItem alloc] initWithTitle:@"Get Info" action:@selector(getInfo:) keyEquivalent:@"i"] autorelease];
	[item setTarget:[NSApp delegate]];	
	[_contextMenu addItem:item];

	item = [[[NSMenuItem alloc] initWithTitle:@"Reveal in Finder" action:@selector(revealInFinder:) keyEquivalent:@""] autorelease];
	[item setTarget:self];	
	[_contextMenu addItem:item];

	[_contextMenu addItem:[NSMenuItem separatorItem]];

	item = [[[NSMenuItem alloc] initWithTitle:@"Search for Screenshot" action:@selector(searchForScreenShot) keyEquivalent:@""] autorelease];
	[item setTarget:self];	
	[_contextMenu addItem:item];

	item = [[[NSMenuItem alloc] initWithTitle:@"Search for ROM" action:@selector(searchForROM) keyEquivalent:@""] autorelease];
	[item setTarget:self];	
	[_contextMenu addItem:item];
	
	return _contextMenu;
	
}

- (void)play
{
	[(MAME_Library_AppDelegate *)[NSApp delegate] launchGame:self];
}

- (BOOL)searchForScreenShot
{

	if (_photo == [(MAME_Library_AppDelegate *)[NSApp delegate] valueForKey:@"missingImage"]) {
		[_photo release];
		_photo = nil;
	}

	NSString *screenshotPath;

	screenshotPath = [NSString stringWithFormat:@"%@/%@/0000.png",[[NSUserDefaults standardUserDefaults] stringForKey:@"MLScreenShotsPath"],[self valueForKey:@"name"]];
	
//	NSLog(@"screenshotPath: %@",screenshotPath);
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:screenshotPath]) {
		[self setValue:screenshotPath forKey:@"screenshotPath"];		
		return TRUE;
	}
	
	screenshotPath = [NSString stringWithFormat:@"%@/%@.png",[[NSUserDefaults standardUserDefaults] stringForKey:@"MLScreenShotsPath"],[self valueForKey:@"name"]];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:screenshotPath]) {
		[self setValue:screenshotPath forKey:@"screenshotPath"];
		return TRUE;
	}	

	screenshotPath = [NSString stringWithFormat:@"%@/%@.jpg",[[NSUserDefaults standardUserDefaults] stringForKey:@"MLScreenShotsPath"],[self valueForKey:@"name"]];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:screenshotPath]) {
		[self setValue:screenshotPath forKey:@"screenshotPath"];
		return TRUE;
	}			

	return FALSE;
}

- (BOOL)searchForROM
{

	NSString *romPath = [NSString stringWithFormat:@"%@/%@.zip",[[NSUserDefaults standardUserDefaults] stringForKey:@"MLROMsPath"],[self valueForKey:@"name"]];		
			
	if ([[NSFileManager defaultManager] fileExistsAtPath:romPath]) {
//		if (nil == [self valueForKey:@"romPath"]) {
//			NSLog(@"Found my ROM: %@",[self valueForKey:@"name"]);
//			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"MLRomPathFound" object:self]];
//		}
		[self setValue:romPath forKey:@"romPath"];
		[self saveMetadata];
		
		return TRUE;
	} else {
//		NSLog(@"Cannot find my ROM: %@",[self valueForKey:@"name"]);
		[self setValue:nil forKey:@"romPath"];
		[self deleteMetadata];
	}
	
	return FALSE;

}

#pragma mark -
#pragma mark Spotlight Metadata

- (NSDictionary *)metadataDictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:	
			[self valueForKey:@"desc"],kMDItemDisplayName,			
														nil];
}

- (void)saveMetadata
{
	NSString *metadataPath = [self metadataPath]; 
	[[self metadataDictionary] writeToFile:metadataPath atomically:NO];	

	[[NSWorkspace sharedWorkspace] setIcon:[self photo] forFile:metadataPath options:0];
	
}

- (NSString *)metadataPath
{
	NSString *metadataDir = [MLMetadataPath stringByExpandingTildeInPath];			
	return [[metadataDir stringByAppendingPathComponent:[self valueForKey:@"name"]] stringByAppendingPathExtension:MLMetadataPathExtension];
}

- (void)deleteMetadata
{
	[[NSFileManager defaultManager] removeItemAtPath:[self metadataPath] error:nil];
}


// The required methods of the IKImageBrowserItem protocol.
#pragma mark -
#pragma mark IKImageBrowserItem protocol

// -------------------------------------------------------------------------
//	imageRepresentationType:
//
//	Set up the image browser to use a path representation.
// -------------------------------------------------------------------------
- (NSString*)imageRepresentationType
{
	return IKImageBrowserNSImageRepresentationType;
}

// -------------------------------------------------------------------------
//	imageRepresentation:
//
//	Give the path representation to the image browser.
// -------------------------------------------------------------------------
- (id)imageRepresentation
{
	return [self photo];
}

// -------------------------------------------------------------------------
//	imageUID:
//
//	Use the absolute file path as the identifier.
// -------------------------------------------------------------------------
- (NSString*)imageUID
{
    return [[[self objectID] URIRepresentation] absoluteString]; 
}

- (NSString *) imageTitle
{
	return [self valueForKey:@"desc"];
}



@end
