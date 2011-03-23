//
//  MLHistoryParser.m
//  MAME Library
//
//  Created by Johnnie Walker on 04/09/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLHistoryParser.h"
#import "MAME_Library_AppDelegate.h"

@implementation MLHistoryParser
-(void)parseHistoryDataAtPath:(NSString *)path
{
	NSString *history;
	
	if (history = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]) {
		NSPersistentStoreCoordinator *coordinator = [(MAME_Library_AppDelegate *)[NSApp delegate] persistentStoreCoordinator];
		if (coordinator != nil) {
			_context = [[NSManagedObjectContext alloc] init];
			[_context setPersistentStoreCoordinator: coordinator];
			[_context setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];	// user changes get preference - we'll pick up changes next update anyway
		}

		_model = [(MAME_Library_AppDelegate *)[NSApp delegate] managedObjectModel];	

		[NSThread detachNewThreadSelector:@selector(_parseHistory:) toTarget:self withObject:history];   	
	}

}

-(void)_parseHistory:(NSString *)historyString {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSLog(@"_parseHistoryData");
	NSScanner *scanner = [NSScanner scannerWithString:historyString];
	
	NSString *buffer;
	NSString *gameName;
	NSFetchRequest *fetchRequest;
	NSManagedObject *history;
	NSManagedObject *game;	
	NSEnumerator *gameNamesEnu;
	NSMutableSet *gamesForHistory;
	NSMutableArray *allGames;
	NSError *error;
	
	int gamesSinceSave = 0;
	
	while (![scanner isAtEnd]) {
		buffer = nil;
		[scanner scanUpToString:@"$info=" intoString:NULL];
		[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&buffer];	
		NSArray *gameNames = [[buffer substringFromIndex:6] componentsSeparatedByString:@","];
		NSLog(@"games: %@",gameNames);	
		[scanner scanUpToString:@"$bio" intoString:NULL];
		[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
		[scanner scanUpToString:@"$end" intoString:&buffer];		

		if ([gameNames count] > 0) {
			history = nil;
			allGames = [NSMutableArray arrayWithCapacity:[gameNames count]];
			gameNamesEnu = [gameNames objectEnumerator];
			while (gameName = [gameNamesEnu nextObject]) {
				if (![gameName isEqualToString:@""]) {
					fetchRequest = [_model fetchRequestFromTemplateWithName:@"gameWithName" substitutionVariables:[NSDictionary dictionaryWithObject:gameName forKey:@"name"]];
					NSArray *games = [_context executeFetchRequest:fetchRequest error:&error];
					if ([games count]) {
						game = [games objectAtIndex:0];
						history = [game valueForKey:@"history"];
						[allGames addObject:game];					
					}
				}
			}
			if (nil == history) {
				//NSLog(@"history doesn't exist.");
				history = [NSEntityDescription insertNewObjectForEntityForName:@"history" inManagedObjectContext:_context];
			}

			//NSLog(@"info length: %i: %@",[buffer length],buffer);	
			[history setValue:[buffer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"bio"];
			gamesForHistory = [history mutableSetValueForKey:@"games"];
			[gamesForHistory addObjectsFromArray:allGames];			
		}			

		[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];

		gamesSinceSave++;		
		if (gamesSinceSave == 256) {
			gamesSinceSave = 0;
			[self saveAction:self];
		}
	}
		
	[pool release];		
}

- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    if (![_context save:&error]) {
		NSLog(@"error: %@",error);
        [[NSApplication sharedApplication] presentError:error];
    }	
	
	[(MAME_Library_AppDelegate *)[NSApp delegate] performSelectorOnMainThread:@selector(forceFetch:) withObject:nil waitUntilDone:FALSE];
}

@end
