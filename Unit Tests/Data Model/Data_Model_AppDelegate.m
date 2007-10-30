//
//  Data_Model_AppDelegate.m
//  Data Model
//
//  Created by Johnnie Walker on 03/07/2007.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import "Data_Model_AppDelegate.h"
#import "MAMEXMLParser.h"
@implementation Data_Model_AppDelegate


/**
    Returns the support folder for the application, used to store the Core Data
    store file.  This code uses a folder named "Data_Model" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportFolder {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Data_Model"];
}


/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle and all of the 
    framework bundles.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    NSMutableSet *allBundles = [[NSMutableSet alloc] init];
    [allBundles addObject: [NSBundle mainBundle]];
    [allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
    [allBundles release];
    
    return managedObjectModel;
}


/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The folder for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {

    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSError *error;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"Data_Model.sql"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    

    return persistentStoreCoordinator;
}


/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *) managedObjectContext {

    if (managedObjectContext != nil) {
        return managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}


/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
 
- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
		NSLog(@"error: %@",error);
        [[NSApplication sharedApplication] presentError:error];
    }
}


/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    NSError *error;
    int reply = NSTerminateNow;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				
                // This error handling simply presents error information in a panel with an 
                // "Ok" button, which does not include any attempt at error recovery (meaning, 
                // attempting to fix the error.)  As a result, this implementation will 
                // present the information to the user and then follow up with a panel asking 
                // if the user wishes to "Quit Anyway", without saving the changes.

                // Typically, this process should be altered to include application-specific 
                // recovery steps.  

                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } 

                else {
					
                    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } 
        
        else {
            reply = NSTerminateCancel;
        }
    }
    
    return reply;
}


/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void) dealloc {
//	[numberFormatter release];
	
    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
    [super dealloc];
}

- (IBAction)openXMLFile:(id)sender {
 
    NSArray *fileTypes = [NSArray arrayWithObject:@"xml"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    NSString *startingDir = [[NSUserDefaults standardUserDefaults] objectForKey:@"StartingDirectory"];
    if (!startingDir)
        startingDir = NSHomeDirectory();
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel beginSheetForDirectory:startingDir file:nil types:fileTypes
      modalForWindow:window modalDelegate:self
      didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
      contextInfo:nil];
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	[parser parseXMLFile:filename];
	return YES;
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSString *pathToFile = nil;
    if (returnCode == NSOKButton) {
        pathToFile = [[[sheet filenames] objectAtIndex:0] copy];
    }
    if (pathToFile) {
        NSString *startingDir = [pathToFile stringByDeletingLastPathComponent];		
        [[NSUserDefaults standardUserDefaults] setObject:startingDir forKey:@"StartingDirectory"];
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:pathToFile]];
        [parser parseXMLFile:pathToFile];
    }
}

//- (NSManagedObject *)entityFromNode:(NSXMLElement *)node withStructure:(NSDictionary *)structure {
//
////	NSLog(@"Making a new: %@",[structure valueForKey:@"entity"]);
//	NSManagedObject *entity = [NSEntityDescription insertNewObjectForEntityForName:[structure valueForKey:@"entity"] inManagedObjectContext:[self managedObjectContext]];		
////	NSLog(@"New %@: %@",[structure valueForKey:@"entity"],entity);
//
//	// attributes
//	NSDictionary *attributes = [structure objectForKey:@"attributes"];
//	if (attributes) {
//		NSEnumerator *attributeKeyEnu = [attributes keyEnumerator];
//		id attributeKey;
//		while (attributeKey = [attributeKeyEnu nextObject]) {
//			NSDictionary *attribute = [attributes objectForKey:attributeKey];
//			id entityKey = attributeKey;
//			if ([attribute objectForKey:@"maps-to"] != nil && ![[attribute objectForKey:@"maps-to"] isEqualToString:@""]) {
//				entityKey = [attribute objectForKey:@"maps-to"];			
//			}			
//			if ([node attributeForName:attributeKey]) {
//				[entity setValue:[self valueForData:[[node attributeForName:attributeKey] stringValue] usingType:[attribute objectForKey:@"type"]] forKey:entityKey];							
//			}
//		}
//	}
//	
//	// elements
//	NSDictionary *elements = [structure objectForKey:@"elements"];
//	if (elements) {
//		NSEnumerator *elementKeyEnu = [elements keyEnumerator];
//		id elementKey;
//		while (elementKey = [elementKeyEnu nextObject]) {
//			NSDictionary *element = [elements objectForKey:elementKey];
//			NSArray *nodeElements = [node elementsForName:elementKey];
//			if ([nodeElements count] > 0) {
//				id entityKey = elementKey;
//				if ([element objectForKey:@"maps-to"] != nil && ![[element objectForKey:@"maps-to"] isEqualToString:@""]) {
//					entityKey = [element objectForKey:@"maps-to"];
//				}
//				id value = [self valueForData:[[nodeElements objectAtIndex:0] stringValue] usingType:[element objectForKey:@"type"]];
//				[entity setValue:value forKey:entityKey];							
//			}			
//		}
//	}
//	
//	// nested entities
//	NSDictionary *nestedEntityDict = [structure objectForKey:@"entities"];
//	if (nestedEntityDict) {
//		NSEnumerator *nestedEntitiesEnu = [nestedEntityDict keyEnumerator];
//		id nestedEntityKey;
//		while (nestedEntityKey = [nestedEntitiesEnu nextObject]) {	
////			NSLog(@"nestedEntityKey: %@",nestedEntityKey);
//			id nestedEntityStructure = [nestedEntityDict objectForKey:nestedEntityKey];
//			NSArray *entityElements = [node elementsForName:[nestedEntityStructure objectForKey:@"entity"]];	// find the elements for this entitiy type
////			NSLog(@"entityElements: %@",entityElements);
//			NSEnumerator *entityElementsEnu = [entityElements objectEnumerator];					
//			id nextEntityNode;
//			if ([[nestedEntityStructure objectForKey:@"to-many"] boolValue]) {
////				// to-many
////				NSLog(@"nestedEntityKey: %@",nestedEntityKey);
//				NSMutableSet *nestedEntitySet = [entity mutableSetValueForKey:nestedEntityKey];		
//				while (nextEntityNode = [entityElementsEnu nextObject]) {
//					NSManagedObject *nestedEntity = [self entityFromNode:nextEntityNode withStructure:nestedEntityStructure]; // each of these elements becomes a nested entity
////					NSLog(@"parentEntity: %@",entity);
////					NSLog(@"nestedEntity: %@",nestedEntity);
////					NSLog(@"nestedEntityStructure: %@",nestedEntityStructure);					
//					[nestedEntitySet addObject:nestedEntity];
//				}		
//			} else {
//				// to-one
//				if (nextEntityNode = [entityElementsEnu nextObject]) {
//					NSManagedObject *nestedEntity = [self entityFromNode:nextEntityNode withStructure:nestedEntityStructure]; // each of these elements becomes a nested entity			
//					[entity setValue:nestedEntity forKey:nestedEntityKey];
//				}
//			}
//		}		
//	}
//	
//	return entity;
//}
//
//- (id)valueForData:(id)data usingType:(id)type {
//
//	if ([type isEqualToString:@"date"]) {
//		return [NSDate dateWithNaturalLanguageString:data];
//	}	
////	if ([type isEqualToString:@"boolean"]) {
////		return [numberFormatter numberFromString:data];
////	}		
//	if ([type isEqualToString:@"integer"] || [type isEqualToString:@"boolean"]) {
////		NSLog(@"integer from data: %@ (%@) formatter: %@",data,[data className],[numberFormatter className]);
//		int i = atoi([data cString]);
//		return [NSNumber numberWithInt:i];
//	}		
//	if ([type isEqualToString:@"float"]) {
//		double d = atof([data cString]);
//		return [NSNumber numberWithDouble:d];
//	}		
//	
//	return data;
//}
//
//- (IBAction)parseXML:(id)sender {
//	
//	if (numberFormatter == nil) {
//		numberFormatter = [[NSNumberFormatter alloc] init];
//		[numberFormatter setGeneratesDecimalNumbers:FALSE];
//	}
//
//	NSDictionary *structure = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Structure" ofType:@"plist"]];
//	NSDictionary *gameStructure = [[structure objectForKey:@"entities"] objectForKey:@"games"];	
////	NSLog(@"gameStructure: %@",gameStructure);
//	
//	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:@"/Users/mrwalker/developer/MAME Library/mame.small.xml"] options:0 error:NULL];	
////	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:@"/Users/mrwalker/developer/MAME Library/mame.xml"] options:0 error:NULL];	
//	
//	NSArray *children = [[doc rootElement] children];
//	NSLog(@"games to parse: %i",[children count]);
//	NSEnumerator *enu = [children objectEnumerator];
//	id child;
//	int index = 1;
//	int storeCount = 1;	
//	while (child = [enu nextObject]) {
//		NSLog(@"%@ (%i)",[[child attributeForName:@"name"] stringValue],index);
//		[self setValue:[[child attributeForName:@"name"] stringValue] forKey:@"status"];
//		[self entityFromNode:child withStructure:gameStructure];
//		index++;
//		storeCount++;
//		if (storeCount == 64) {			
//			[self saveAction:self];
//			[[self managedObjectContext] reset];
//			storeCount = 0;
//		}
//	}
//		
//	[doc release];
//
//}


@end
