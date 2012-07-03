//
//  MAMEXMLParser.m
//  Data Model
//
//  Created by Johnnie Walker on 14/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MAMEXMLParser.h"
#import "MAME_Library_AppDelegate.h"
#import "MLGame.h"
#include <stdlib.h>

@implementation MAMEXMLParser

- (void)importFromMAME
{
	[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"animate"];
	[self setValue:@"Collecting data from MAME OS X" forKey:@"status"];
	if (_progressWindow == nil) {
		[NSBundle loadNibNamed:@"MAMEImport" owner:self];
	}	
	[_progressWindow makeKeyAndOrderFront:self];

    [NSThread detachNewThreadSelector:@selector(getXMLFromMAME:) toTarget:self withObject:nil];
}

- (void)importFromMAMEWithUserInfo:(NSDictionary *)userinfo;
{
	NSArray *games = [userinfo valueForKey:@"games"];
	_userInfoByGameName = [[NSMutableDictionary alloc] initWithCapacity:[games count]]; 

	_userInfo = [userinfo retain];

	NSEnumerator *gamesEnu = [games objectEnumerator];
	NSDictionary *gameUserInfo;
	
	while (gameUserInfo = [gamesEnu nextObject]) {
		[_userInfoByGameName setObject:gameUserInfo forKey:[gameUserInfo valueForKey:@"name"]];
	}
	
//	NSLog(@"_userInfoByGameName: %@",_userInfoByGameName);

	[self importFromMAME];
}

- (void)getXMLFromMAME:(id)sender
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];    
    
	NSString *mamePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"MLMAMEPath"];
    NSString *mameutilPath = mamePath;
    NSString *args = nil;
    
    BOOL isDirectory = NO;
	BOOL exists = NO;
	exists = [[NSFileManager defaultManager] fileExistsAtPath:mamePath isDirectory:&isDirectory];
	    
	if (exists && isDirectory) {
        // MAME OS X
        mameutilPath = [[[NSUserDefaults standardUserDefaults] stringForKey:@"MLMAMEPath"] stringByAppendingPathComponent:@"Contents/MacOS/mameosx-util"];
        args = @"--listxml";
	} else {
        // SDLMame        
        args = @"-listxml";
    }
        
//	NSLog(@"mameutilPath: %@",mameutilPath);
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:mameutilPath]) {
		NSTask *task = [[NSTask alloc] init];
		[task setLaunchPath: mameutilPath];
		[task setArguments: [NSArray arrayWithObject:args]];
		NSPipe *pipe = [NSPipe pipe];
		[task setStandardOutput: pipe];
		NSFileHandle *file = [pipe fileHandleForReading];		
		[task launch];
		NSData *data = [file readDataToEndOfFile];

		[NSThread detachNewThreadSelector:@selector(doParseWithData:) toTarget:self withObject:data];   	
	}
	
	[pool release];	
}

-(void)parseXMLFile:(NSString *)file {

	if (_progressWindow == nil) {
		[NSBundle loadNibNamed:@"MAMEImport " owner:self];
	}	
	[_progressWindow makeKeyAndOrderFront:self];
	
	NSData *xmlData = [NSData dataWithContentsOfFile:file];
	
    [NSThread detachNewThreadSelector:@selector(doParse:) toTarget:self withObject:xmlData];   	
//	[self doParse:file];
}

-(void)doParseWithData:(NSData *)data {
	_gameCount = 0;
	_gamesSinceSave = 0;	
	_totalGames = 6674;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	_parser = [[NSXMLParser alloc] initWithData:data];	

	[self setValue:[NSNumber numberWithBool:TRUE] forKey:@"importing"];

    NSPersistentStoreCoordinator *coordinator = [(MAME_Library_AppDelegate *)[NSApp delegate] persistentStoreCoordinator];
    if (coordinator != nil) {
        _context = [[NSManagedObjectContext alloc] init];
        [_context setPersistentStoreCoordinator: coordinator];
		[_context setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];	// user changes get preference - we'll pick up changes next update anyway
    }

	_model = [(MAME_Library_AppDelegate *)[NSApp delegate] managedObjectModel];	
	[_parser setDelegate:self];
	[_parser parse];
	[pool release];
}

- (void) dealloc {
	[_parser release];
	[super dealloc];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

	NSArray *directAttributes;
	NSArray *nestedEntityLists;	
//	NSArray *nestedEntities;	
	NSFetchRequest *fetchRequest;
//	NSEnumerator *nestedEntitiesEnu;
//	NSString *nestedEntityKey;
//	NSManagedObject *nestedEntity;

//	NSLog(@"didStartElement: %@",elementName);

	if ([elementName isEqualToString:@"game"]) {	
	
		NSError *error;
		fetchRequest = [_model fetchRequestFromTemplateWithName:@"gameWithName" substitutionVariables:[NSDictionary dictionaryWithObject:[attributeDict valueForKey:@"name"] forKey:@"name"]];
		// NSLog(@"fetchRequest: %@",fetchRequest);
		NSArray *games = [_context executeFetchRequest:fetchRequest error:&error];
				
		if (([games count] > 0) && (_currentGame = [games objectAtIndex:0])) {
			[self setValue:@"Updating" forKey:@"statusPrefix"];
			
			// remove all linked entities
			nestedEntityLists = [NSArray arrayWithObjects:@"biossets",@"chips",@"disks",@"displays",@"dipswitches",@"inputs",@"samples",@"roms",nil];
			[self removeNestedEntitiesWithRelationshipNames:nestedEntityLists fromEntity:_currentGame];
			
//			nestedEntities = [NSArray arrayWithObjects:@"driver",@"sound",nil];
//			nestedEntitiesEnu = [nestedEntities objectEnumerator];
//			while (nestedEntityKey = [nestedEntitiesEnu nextObject]) {
//				if ([_currentGame valueForKey:nestedEntityKey] != nil) {
//					[_context deleteObject:[_currentGame valueForKey:nestedEntityKey]];
//				}				
//			}
			
		} else {
			[self setValue:@"Adding" forKey:@"statusPrefix"];
			_currentGame = [NSEntityDescription insertNewObjectForEntityForName:@"game" inManagedObjectContext:_context];		
			[_currentGame setValue:[attributeDict valueForKey:@"name"] forKey:@"name"];	
			[_currentGame setValue:[NSDate date] forKey:@"dateadded"];		
		}	
		
		[_currentGame retain];		

		[_currentGame searchForROM];
		[_currentGame searchForScreenShot];
		
		directAttributes = [NSArray arrayWithObjects:@"sourcefile",@"cloneof",@"romof",nil];
		[self setAttrributesFromDictionary:attributeDict withKeys:directAttributes onEntity:_currentGame];	
		
		_currentEntity = _currentGame;
				
//	} else if ([elementName isEqualToString:@"biosset"]) {	
//		[self createEntityWithName:elementName addingAttributes:[NSArray arrayWithObjects:@"name",@"description",@"default",nil] fromAttributeDictionary:attributeDict];
//	} else if ([elementName isEqualToString:@"disk"]) {	
//		[self createEntityWithName:elementName addingAttributes:[NSArray arrayWithObjects:@"name",@"md5",@"sha1",@"merge",@"region",@"index",@"status",nil] fromAttributeDictionary:attributeDict];
//	} else if ([elementName isEqualToString:@"sample"]) {	
//		[self createEntityWithName:elementName addingAttributes:[NSArray arrayWithObjects:@"name",nil] fromAttributeDictionary:attributeDict];
//	} else if ([elementName isEqualToString:@"chip"]) {	
//		[self createEntityWithName:elementName addingAttributes:[NSArray arrayWithObjects:@"name",@"type",@"clock",nil] fromAttributeDictionary:attributeDict];
//	} else if ([elementName isEqualToString:@"display"]) {	
//		[self createEntityWithName:elementName addingAttributes:[NSArray arrayWithObjects:@"type",@"rotate",@"flipx",@"width",@"height",@"refresh",nil] fromAttributeDictionary:attributeDict];
//	} else if ([elementName isEqualToString:@"sound"]) {	
//		directAttributes = [NSArray arrayWithObjects:@"channels",nil];
//		NSManagedObject *sound = [_currentGame valueForKey:elementName];
//		if (sound == nil) {
//			[self createEntityWithName:elementName addingAttributes:directAttributes fromAttributeDictionary:attributeDict];
//		} else {
//			[self setAttrributesFromDictionary:attributeDict withKeys:directAttributes onEntity:sound];
//		}		
	} else if ([elementName isEqualToString:@"input"]) {	
		[self createEntityWithName:elementName addingAttributes:[NSArray arrayWithObjects:@"service",@"tilt",@"players",@"buttons",@"coins",nil] fromAttributeDictionary:attributeDict];
//	} else if ([elementName isEqualToString:@"dipswitch"]) {	
//		[self createEntityWithName:elementName addingAttributes:[NSArray arrayWithObjects:@"name",nil] fromAttributeDictionary:attributeDict];
	} else if ([elementName isEqualToString:@"driver"]) {	
		directAttributes = [NSArray arrayWithObjects:@"status",@"emulation",@"color",@"sound",@"graphic",@"cocktail",@"protection",@"savestate",@"palettesize",nil];
		NSManagedObject *driver = [_currentGame valueForKey:elementName];
		if (driver == nil) {
			[self createEntityWithName:elementName addingAttributes:directAttributes fromAttributeDictionary:attributeDict];
		} else {
			[self setAttrributesFromDictionary:attributeDict withKeys:directAttributes onEntity:driver];
		}		
//	} else if ([elementName isEqualToString:@"rom"]) {	
//		[self createEntityWithName:elementName addingAttributes:[NSArray arrayWithObjects:@"name",@"bios",@"size",@"crc",@"sha1",@"md5",@"merge",@"status",@"dispose",@"region",@"offset",nil] fromAttributeDictionary:attributeDict];
//	} else if ([elementName isEqualToString:@"dipvalue"]) {	
//		directAttributes = [NSArray arrayWithObjects:@"name",@"default",nil];
//		NSManagedObject *entity = [NSEntityDescription insertNewObjectForEntityForName:elementName inManagedObjectContext:_context];		
//		[self setAttrributesFromDictionary:attributeDict withKeys:directAttributes onEntity:entity];
//		[entity setValue:_currentEntity forKey:@"dipswitch"];
//	} else if ([elementName isEqualToString:@"control"]) {	
//		directAttributes = [NSArray arrayWithObjects:@"type",@"minimum",@"maximum",@"sensitivity",@"keydelta",@"reverse",nil];
//		NSManagedObject *entity = [NSEntityDescription insertNewObjectForEntityForName:elementName inManagedObjectContext:_context];		
//		[self setAttrributesFromDictionary:attributeDict withKeys:directAttributes onEntity:entity];
//		[entity setValue:_currentEntity forKey:@"input"];
	}

	
}

- (void)createEntityWithName:(NSString *)elementName addingAttributes:(NSArray *)attributes fromAttributeDictionary:(NSDictionary *)attributeDict
{
	NSManagedObject *entity = [NSEntityDescription insertNewObjectForEntityForName:elementName inManagedObjectContext:_context];		
	[self setAttrributesFromDictionary:attributeDict withKeys:attributes onEntity:entity];
	[entity setValue:_currentGame forKey:@"game"];
	_currentEntity = entity;
}

- (void)removeNestedEntitiesWithRelationshipNames:(NSArray *)names fromEntity:(NSManagedObject *)entity
{
	NSEnumerator *enu = [names objectEnumerator];
	NSEnumerator *senu;
	NSManagedObject *nestedEntity;
	NSString *relationshipKey;
	while (relationshipKey = [enu nextObject]) {
		NSMutableSet *nestedEntitySet = [entity mutableSetValueForKey:relationshipKey];		
		senu = [nestedEntitySet objectEnumerator];
		while (nestedEntity = [senu nextObject]) {
			[_context deleteObject:nestedEntity];
		}
		[nestedEntitySet removeAllObjects];
	}
}

- (void)setAttrributesFromDictionary:(NSDictionary *)attributeDict withKeys:(NSArray *)attributeKeys onEntity:(NSManagedObject *)entity
{
	NSEntityDescription *description = [entity entity];
	NSDictionary *properties = [description propertiesByName];
	NSEnumerator *enu = [attributeKeys objectEnumerator];
	NSString *attributeKey;
	NSString *entityKey;	
	while (attributeKey = [enu nextObject]) {
		if ([attributeDict valueForKey:attributeKey]) {
			entityKey = attributeKey;
			if ([entityKey isEqualToString:@"description"]) {
				entityKey = @"desc";
			}
			
			if ([[properties valueForKey:attributeKey] attributeType] == NSInteger16AttributeType
				|| [[properties valueForKey:attributeKey] attributeType] == NSInteger32AttributeType
				|| [[properties valueForKey:attributeKey] attributeType] == NSInteger64AttributeType
				|| [[properties valueForKey:attributeKey] attributeType] == NSBooleanAttributeType) {
				int i = atoi([[attributeDict valueForKey:attributeKey] cString]);
				[entity setValue:[NSNumber numberWithInt:i] forKey:entityKey];				
			} else if ([[properties valueForKey:attributeKey] attributeType] == NSFloatAttributeType
						|| [[properties valueForKey:attributeKey] attributeType] == NSDoubleAttributeType) {
				double d = atof([[attributeDict valueForKey:attributeKey] cString]);
				[entity setValue:[NSNumber numberWithDouble:d] forKey:entityKey];				
			} else {
				[entity setValue:[attributeDict valueForKey:attributeKey] forKey:entityKey];			
			}		
		} else if ([[properties valueForKey:attributeKey] defaultValue]) {
//			NSLog(@"[[properties valueForKey:attributeKey] defaultValue]: %@",[[properties valueForKey:attributeKey] defaultValue]);
			[entity setValue:[[properties valueForKey:attributeKey] defaultValue] forKey:entityKey];
		}
	}	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {

	NSString *lastFoundCharacters = _foundCharacters;

	if (nil != lastFoundCharacters && [lastFoundCharacters length] > 0) {
		_foundCharacters = [[lastFoundCharacters stringByAppendingString:string] retain];	
	} else {
		_foundCharacters = [string retain];	
	}

	if (lastFoundCharacters != nil) {
		[lastFoundCharacters release];
		lastFoundCharacters = nil;
	}
	
//	if ([_foundCharacters rangeOfString:@"&"].location != NSNotFound) {
//		NSLog(@"%@ (%@)",_foundCharacters,lastFoundCharacters);
//	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {

	if ([elementName isEqualToString:@"description"]) {	
		[_currentEntity setValue:[_foundCharacters stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"desc"];	
		[self setValue:[NSString stringWithFormat:@"%@ %@",[self valueForKey:@"statusPrefix"],[_currentGame valueForKey:@"desc"]] forKey:@"status"];
	} else if ([elementName isEqualToString:@"year"]) {			
		[_currentEntity setValue:[NSDate dateWithNaturalLanguageString:_foundCharacters] forKey:@"year"];				
	} else if ([elementName isEqualToString:@"manufacturer"]) {			
		[_currentEntity setValue:[_foundCharacters stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"manufacturer"];				
	} else if ([elementName isEqualToString:@"game"]) {			
		if (nil != _userInfoByGameName && nil != [_userInfoByGameName valueForKey:[_currentGame valueForKey:@"name"]]) {
			[_currentGame applyUserGameInfo:[_userInfoByGameName valueForKey:[_currentGame valueForKey:@"name"]]];
		}
		
		//NSLog(@"_userInfoByGameName[%@]:",[_currentGame valueForKey:@"name"],[_userInfoByGameName valueForKey:[_currentGame valueForKey:@"name"]]);

		if (_currentGame != nil) {
			[_currentGame release];
			_currentGame = nil;
		}
		_currentEntity = nil;
		_gameCount++;		
		_gamesSinceSave++;
		[self setValue:[NSNumber numberWithFloat:(100 * (float) _gameCount / _totalGames)] forKey:@"progress"];
		if (_gamesSinceSave == 256) {
			_gamesSinceSave = 0;
			[self saveAction:self];
			//[_context reset];
		}
	}	

	[_foundCharacters release];
	_foundCharacters = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	[_progressWindow orderOut:self];
	[self saveAction:self];
	[self setValue:[NSNumber numberWithBool:FALSE] forKey:@"importing"];
	[[NSUserDefaults standardUserDefaults] setValue:[(MAME_Library_AppDelegate *)[NSApp delegate] mameVersionString] forKey:@"MLLastMAMEVersion"];
	[[NSUserDefaults standardUserDefaults] setValue:[[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"MLLastMLImportVersion"];
	
	if (nil != _userInfo) {
		// [self importCollectionsFromUserinfo:_userInfo];
	}
	
	[_userInfo release];
	_userInfo = nil;
	[_userInfoByGameName release];
	_userInfoByGameName = nil;
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
