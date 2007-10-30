//
//  MLCollection.m
//  MAME Library
//
//  Created by Johnnie Walker on 16/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLCollection.h"
#import "MLGame.h"

@implementation MLCollection

- (NSDictionary *)titleDictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:[self valueForKey:@"title"],@"title",[self valueForKey:@"image"],@"image",[[self valueForKey:@"games"] count],@"gamesCount",nil];
}

- (NSDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	[dictionary setValue:[self valueForKey:@"title"] forKey:@"title"];
	[dictionary setValue:[[[self objectID] URIRepresentation] absoluteString] forKey:@"objectID"];	
	
	if (nil != [self valueForKey:@"predicateString"]) {
		[dictionary setValue:[self valueForKey:@"predicateString"] forKey:@"predicate"];	
	}
	if (nil != [self valueForKey:@"limit"]) {
		[dictionary setValue:[self valueForKey:@"limit"] forKey:@"limit"];	
	}
	if (nil != [self valueForKey:@"showClones"]) {
		[dictionary setValue:[self valueForKey:@"showClones"] forKey:@"showClones"];	
	}
	if (nil != [self valueForKey:@"showUnavailable"]) {
		[dictionary setValue:[self valueForKey:@"showUnavailable"] forKey:@"showUnavailable"];	
	}
	if (nil != [self valueForKey:@"parent"]) {
		[dictionary setValue:[[[[self valueForKey:@"parent"] objectID] URIRepresentation] absoluteString] forKey:@"parent"];	
	}
	
	NSArray *games = [self valueForKey:@"games"];
	NSMutableArray *gameTitles = [NSMutableArray arrayWithCapacity:[games count]];
	NSEnumerator *gamesEnu = [games objectEnumerator];
	MLGame *nextGame;
	while (nextGame = [gamesEnu nextObject]) {
		[gameTitles addObject:[nextGame valueForKey:@"name"]];
	}

	[dictionary setValue:gameTitles forKey:@"games"];	

	NSArray *collections = [self valueForKey:@"collections"];
	NSMutableArray *myCollections = [NSMutableArray arrayWithCapacity:[collections count]];
	NSEnumerator *collectionsEnu = [collections objectEnumerator];
	MLCollection *nextCollection;
	while (nextCollection = [collectionsEnu nextObject]) {
		[myCollections addObject:[nextCollection dictionaryRepresentation]];
	}
	
	[dictionary setValue:myCollections forKey:@"collections"];		
	
	return dictionary;
}

- (void)applyUserCollectionInfo:(NSDictionary *)userCollectionInfo;
{
	[self setValue:[userCollectionInfo valueForKey:@"title"] forKey:@"title"];
	
	if (nil != [userCollectionInfo valueForKey:@"predicate"]) {
		[self setValue:[userCollectionInfo valueForKey:@"predicate"] forKey:@"predicateString"];	
		[self setValue:[NSNumber numberWithInt:3] forKey:@"type"];	
	}
	if (nil != [userCollectionInfo valueForKey:@"limit"]) {
		[self setValue:[userCollectionInfo valueForKey:@"limit"] forKey:@"limit"];	
	}
	if (nil != [userCollectionInfo valueForKey:@"showClones"]) {
		[self setValue:[userCollectionInfo valueForKey:@"showClones"] forKey:@"showClones"];	
	}
	if (nil != [userCollectionInfo valueForKey:@"showUnavailable"]) {
		[self setValue:[userCollectionInfo valueForKey:@"showUnavailable"] forKey:@"showUnavailable"];	
	}
	
	NSManagedObjectContext *context = [self managedObjectContext];
	NSPersistentStoreCoordinator *coordinator = [context persistentStoreCoordinator];
	NSManagedObjectModel *model = [coordinator managedObjectModel];
	NSFetchRequest *fetchRequest;	
	NSError *error;	
	
	if (nil != [userCollectionInfo valueForKey:@"parent"]) {
		NSManagedObjectID *parentObjectID = [coordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:[userCollectionInfo valueForKey:@"parent"]]];
		MLCollection *parent = (MLCollection *)[context objectWithID:parentObjectID];	
		[self setValue:parent forKey:@"parent"];	
	}	
	
	if (nil != [userCollectionInfo valueForKey:@"games"] && [[userCollectionInfo valueForKey:@"games"] count] > 0) {				
		NSArray *fetchedGames;
		MLGame *fetchedGame;		
		
		NSArray *gameTitles = [userCollectionInfo valueForKey:@"games"];
		NSEnumerator *gameTitlesEnu = [gameTitles objectEnumerator];
		NSString *gameName;
		
		[self setValue:[NSNumber numberWithInt:2] forKey:@"type"];	
		
		NSMutableSet *games = [self mutableSetValueForKey:@"games"];
		
		while (gameName = [gameTitlesEnu nextObject]) {
			fetchRequest = [model fetchRequestFromTemplateWithName:@"gameWithName" substitutionVariables:[NSDictionary dictionaryWithObject:gameName forKey:@"name"]];
			fetchedGames = [context executeFetchRequest:fetchRequest error:&error];							
			if (([fetchedGames count] > 0) && (fetchedGame = [fetchedGames objectAtIndex:0])) {
				[games addObject:fetchedGame];
			}
		}
	}
	
	if (nil != [userCollectionInfo valueForKey:@"collections"] && [[userCollectionInfo valueForKey:@"collections"] count] > 0) {				
		NSArray *collectionIDs = [userCollectionInfo valueForKey:@"collections"];
		NSEnumerator *collectionIDsEnu = [collectionIDs objectEnumerator];
		NSString *collectionID;
		
		[self setValue:[NSNumber numberWithInt:1] forKey:@"type"];	
		
		NSMutableSet *collections = [self mutableSetValueForKey:@"collections"];
		
		while (collectionID = [collectionIDsEnu nextObject]) {
			MLCollection *collection;
			NSManagedObjectID *objectID = [coordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:collectionID]];
			collection = (MLCollection *)[context objectWithID:objectID];
			
			if (nil == collection) {
				collection = [NSEntityDescription insertNewObjectForEntityForName:@"collection" inManagedObjectContext:context];		
			}
			
			[collection applyUserCollectionInfo:userCollectionInfo];	
			[collections addObject:collection];
		}
	}	
}

- (NSPredicate *)predicate
{
	NSPredicate *predicate = [self gamesPredicate];
	NSArray *predicates;
	
	if (![[self valueForKey:@"showClones"] boolValue]) {
		NSPredicate *noClonesPredicate = [NSPredicate predicateWithFormat:@"cloneof == null"];
		predicates = [NSArray arrayWithObjects:predicate,noClonesPredicate,nil];
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	}
	
	if (![[self valueForKey:@"showUnavailable"] boolValue]) {
		NSPredicate *hideUnavailablePredicate = [NSPredicate predicateWithFormat:@"romPath != null AND driver != null"];
		predicates = [NSArray arrayWithObjects:predicate,hideUnavailablePredicate,nil];
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	}	
	
	return predicate;
}

- (NSPredicate *)gamesPredicate
{
	NSString *predicateString = [self valueForKey:@"predicateString"];
	
	if (nil == predicateString) {
		if ([[self valueForKey:@"type"] intValue] == 1) {
			NSArray *collections = [self valueForKey:@"collections"];
			NSEnumerator *collectionsEnu = [collections objectEnumerator];
			MLCollection *nextCollection;
			NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:[collections count]];
			while (nextCollection = [collectionsEnu nextObject]) {
				[predicates addObject:[nextCollection predicate]];
			}
			//NSLog(@"predicates: %@",predicates);
			return [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
		}
	
		// return a predicate consisting of the games in our collection
		return [self predicateForGamesInArray:[self valueForKey:@"games"]];
	}
	
	if ([[self valueForKey:@"limit"] intValue] > 0) {
		// we have to execute the request here & send back a predicate based on the games' names		
		NSManagedObjectContext *context = [self managedObjectContext];
		NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];		
		NSDictionary *entities = [model entitiesByName];
		NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];	
		[fetchRequest setPredicate:predicate];		
		[fetchRequest setFetchLimit:[[self valueForKey:@"limit"] unsignedIntValue]];
		[fetchRequest setEntity:[entities objectForKey:@"game"]];
//		if (nil != [self valueForKey:@"sortBy"]) {
//			//NSSortDescriptor *sortDescriptor = [
//			//[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
//		}
		NSError *error;		
		NSArray *fetchedGames = [context executeFetchRequest:fetchRequest error:&error];		
		return [self predicateForGamesInArray:fetchedGames];
	}
	
	return [NSPredicate predicateWithFormat:predicateString];
}

- (NSPredicate *)predicateForGamesInArray:(NSArray *)games
{
	if ([games count] > 0) {
		NSMutableString *mutablePredicateString = [NSMutableString stringWithString:@""];
		NSEnumerator *gamesEnu = [games objectEnumerator];
		NSManagedObject *nextGame;
		while (nextGame = [gamesEnu nextObject]) {
			[mutablePredicateString appendFormat:@"name = '%@' OR ",[nextGame valueForKey:@"name"]];			
		}
		[mutablePredicateString deleteCharactersInRange:NSMakeRange([mutablePredicateString length]-4,4)];
		//[mutablePredicateString appendString:@""];
		return [NSPredicate predicateWithFormat:mutablePredicateString];
	}
	return [NSPredicate predicateWithFormat:@"name = nil"];
}

- (void)removeGames:(NSArray *)games
{
	MLGame *nextGame;
	NSEnumerator *gamesEnu = [games objectEnumerator];
	NSMutableSet *myGames = [self mutableSetValueForKey:@"games"];
	while (nextGame = [gamesEnu nextObject]) {
		[myGames removeObject:nextGame];
	}
	
//	NSLog(@"games: %@",[self valueForKey:@"games"]);
}

- (void)addGamesWithNames:(NSArray *)names;
{
	NSManagedObjectContext *context = [self managedObjectContext];
	NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
	NSFetchRequest *fetchRequest;
	NSEnumerator *namesEnu = [names objectEnumerator];
	NSString *nextName;
	NSArray *fetchedGames;
	NSError *error;	
	NSMutableSet *games = [self mutableSetValueForKey:@"games"];
	MLGame *fetchedGame;
	while (nextName = [namesEnu nextObject]) {
		fetchRequest = [model fetchRequestFromTemplateWithName:@"gameWithName" substitutionVariables:[NSDictionary dictionaryWithObject:nextName forKey:@"name"]];
		// NSLog(@"fetchRequest: %@",fetchRequest);
		fetchedGames = [context executeFetchRequest:fetchRequest error:&error];
		if (fetchedGame = [fetchedGames objectAtIndex:0]) {
			[games addObject:fetchedGame];
		}		
	}
}

@end
