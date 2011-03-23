//
//  MAME_Library_AppDelegate.m
//  MAME Library
//
//  Created by Johnnie Walker on 05/01/2007.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import "MAME_Library_AppDelegate.h"
#import "MAMEXMLParser.h"
#import "iTableColumnHeaderCell.h"
#import "MLTableHeaderImageCell.h"
#import "MLGame.h"
#include <stdlib.h>
#import "constants.h"
#import "MLCollection.h"
#import "MLOutlineViewDragController.h"
#import "KFSplitView.h"
#import "MLPreferencesController.h"
#import "MLHistoryParser.h"

@implementation MAME_Library_AppDelegate

#pragma mark -
// Application Setup
#pragma mark Application Setup

- (void)awakeFromNib {

	NSDictionary *mosxPrefs = [NSDictionary dictionaryWithContentsOfFile:[@"~/Library/Preferences/net.mame.mameosx.plist" stringByExpandingTildeInPath]];	
//	NSLog(@"mosxPrefs: %@",mosxPrefs);

	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	if (nil == [ud stringForKey:@"MLMAMEPath"]) {
		[ud setObject:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"net.mame.mameosx"] forKey:@"MLMAMEPath"];
	}
	if (nil == [ud stringForKey:@"MLROMsPath"]) {
		if (nil != mosxPrefs && nil != [mosxPrefs valueForKey:@"RomPath"]) {
			[ud setObject:[mosxPrefs valueForKey:@"RomPath"] forKey:@"MLROMsPath"];
		} else {
			[ud setObject:[@"~/Library/Application Support/Mame OS X/ROMs" stringByExpandingTildeInPath] forKey:@"MLROMsPath"];		
		}		
	}
	if (nil == [ud stringForKey:@"MLScreenShotsPath"]) {
		[ud setObject:[@"~/Library/Application Support/Mame OS X/Screenshots" stringByExpandingTildeInPath] forKey:@"MLScreenShotsPath"];
	}
	if (nil == [ud objectForKey:@"MLPhotoViewBackgroundColor"]) {
		[ud setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.93 alpha:1]] forKey:@"MLPhotoViewBackgroundColor"];
	}
	if (nil == [ud objectForKey:@"MLPhotoSize"]) {
		[ud setFloat:100.0 forKey:@"MLPhotoSize"];
	}		
	
	missingImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"test-signal"]];
	overlayImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"Overlay"]];
	
//	[missingImage setFlipped:YES];
	[missingImage lockFocus];
	[overlayImage drawInRect:NSMakeRect(0,0,[missingImage size].width,[missingImage size].height) fromRect:NSMakeRect(0,0,[overlayImage size].width,[overlayImage size].height) operation:NSCompositeSourceOver fraction:1.0];
	[missingImage unlockFocus];							

}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification 
{			

	NSTimeInterval interval = 3600*24;
	NSDate *lastCheck = [[NSUserDefaults standardUserDefaults] objectForKey:MLLastHistoryCheckTimeKey];
	if (!lastCheck) { 
		lastCheck = [NSDate date]; 
	}
	NSTimeInterval intervalSinceCheck = [[NSDate date] timeIntervalSinceDate:lastCheck];
	if (intervalSinceCheck < interval) {
		// Hasn't been long enough; schedule a check for the future.
		[self performSelector:@selector(checkForHistoryDatUpdates:) withObject:nil afterDelay:(interval-intervalSinceCheck)];
	} else {
		[self checkForHistoryDatUpdates:nil];
	}

	NSFileManager *fileManager = [NSFileManager defaultManager];			
	
	if (![fileManager fileExistsAtPath:[[NSUserDefaults standardUserDefaults] stringForKey:@"MLMAMEPath"]]) {
		// prompt the user to find MAME OS X
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert addButtonWithTitle:@"Cancel"];
			[alert addButtonWithTitle:@"Download"];			
			[alert setMessageText:@"MAME Library cannot find MAME OS X"];
			[alert setInformativeText:@"MAME OS X is required to play games. Would you like to locate MAME OS X now?"];
			[alert setAlertStyle:NSWarningAlertStyle];
			
			int result = [alert runModal];
			
			if (result == NSAlertFirstButtonReturn) {
				[preferencesController setMAMEPath:self];				
			} else if (result == NSAlertThirdButtonReturn) {
				[self getMAMEOSX:self];				
			}	

		//NSLog(@"Can't find MAME OS X anywhere!");
	}
	
	NSString *metadataDir = [MLMetadataPath stringByExpandingTildeInPath];    
	if (![fileManager fileExistsAtPath: metadataDir]) {
        [fileManager createDirectoryAtPath:metadataDir withIntermediateDirectories:YES attributes:nil error:nil];
		[NSThread detachNewThreadSelector:@selector(rebuildMetadata) toTarget:self withObject:nil];
	}	
	
	[self setupAndShowMainWindow];		
}

- (void)rebuildMetadata
{		
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
	NSFileManager *fileManager = [NSFileManager defaultManager];				
    NSArray *paths = [fileManager contentsOfDirectoryAtPath:MLMetadataPath error:nil];
    for (NSString *path in paths) {
		if ([[path pathExtension] isEqualToString:MLMetadataPathExtension]) {
			[fileManager removeItemAtPath:path error:nil];
		}        
    }
	
	// Each thread needs it's own managedObjectContext
	NSManagedObjectContext *threadContext = [[NSManagedObjectContext alloc] init];
	[threadContext setPersistentStoreCoordinator: [self persistentStoreCoordinator]];
	[threadContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
	
	NSFetchRequest *request = [[self managedObjectModel] fetchRequestTemplateForName:@"gamesWithRomPath"];
	NSError *error = nil;
	NSArray *games = [threadContext executeFetchRequest:request error:&error];				
	
    for (MLGame *nextGame in games) {
		[nextGame saveMetadata];        
    }
	
	[threadContext release];
	
	[pool drain];
}

- (void)setupAndShowMainWindow
{
//		// Place the source list view in the left panel.
	[sourceView setFrameSize:[sourceViewPlaceHolder frame].size];
	[sourceViewPlaceHolder addSubview:sourceView];

//		// Place the content view in the right panel.
	[contentView setFrameSize:[contentViewPlaceHolder frame].size];
	[contentViewPlaceHolder addSubview:contentView];

//		// Place the source list view in the left panel.
	[artworkView setFrameSize:[artworkViewPlaceHolder frame].size];
	[artworkViewPlaceHolder addSubview:artworkView];

//		// Place the content view in the right panel.
	[sourceOutlineView setFrameSize:[sourceOutlineViewPlaceHolder frame].size];
	[sourceOutlineViewPlaceHolder addSubview:sourceOutlineView];

	// split views
	[splitView setPositionAutosaveName:@"MLSourceContentSplitView"];
	[sourceListSplitView setPositionAutosaveName:@"MLSourceArtworkSplitView"];	
	[sourceListSplitView setSubview:artworkViewPlaceHolder isCollapsed:[[NSUserDefaults standardUserDefaults] boolForKey:@"MLHideArtworkView"]];			

	
	[browserView setDelegate:self];
	[browserView setDataSource:self];	
	[myRatingIndicator setContinuous:TRUE];
	
	NSColor *bgColor = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"MLPhotoViewBackgroundColor"]];
	
	NSColor *textColor = [NSColor blackColor];
	if ([[bgColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] brightnessComponent] < 0.5) {
		textColor = [NSColor whiteColor];
	}

	NSShadow *textShadow = [[[NSShadow alloc] init] autorelease];
	[textShadow setShadowOffset:NSMakeSize(0,-3.0)];
	[textShadow setShadowBlurRadius:2.0];	
	
	NSFont *textFont = [NSFont boldSystemFontOfSize:11.0];

	NSDictionary *textColorDict = [NSDictionary dictionaryWithObjectsAndKeys:textColor,NSForegroundColorAttributeName,textShadow,NSShadowAttributeName,textFont,NSFontAttributeName,nil];
	NSDictionary *textHighlightColorDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor],NSForegroundColorAttributeName,textFont,NSFontAttributeName,nil];

	[browserView setValue:textHighlightColorDict forKey:IKImageBrowserCellsHighlightedTitleAttributesKey];
	[browserView setValue:textColorDict forKey:IKImageBrowserCellsTitleAttributesKey];		
	//[browserView setCellSize:NSMakeSize(100,100)];

	[browserView setValue:bgColor forKey:IKImageBrowserBackgroundColorKey];
	[scrollView setBackgroundColor:bgColor];
//	[photoView bind:@"backgroundColor" toObject:defaultsController withKeyPath:@"values.MLPhotoViewBackgroundColor" options:nil];	

	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(tableViewDoubleClick:)];

	// set up the iApp style table headers
	iTableColumnHeaderCell *headerCell;
	NSArray *columns = [tableView tableColumns];
	
	for (NSTableColumn *nextColumn in columns ) {
        headerCell = [[iTableColumnHeaderCell alloc] 
                        initTextCell:[[nextColumn headerCell] stringValue]];
		[headerCell bind:@"sortDescriptors" toObject:availableGamesArrayController withKeyPath:@"sortDescriptors" options:nil];
        [nextColumn setHeaderCell:headerCell];
	}

	// fudge in the switch view button
    MLTableHeaderImageCell *imageheaderCell = [[MLTableHeaderImageCell alloc] 
                        initImageCell:[NSImage imageNamed:@"table_view_active"]];
	[imagesTableColumn setHeaderCell:imageheaderCell];
	
	NSImageView *cornerView = [[[NSImageView alloc] init] autorelease];
	[cornerView setImage:[NSImage imageNamed:@"corner"]];
	[tableView setCornerView:cornerView];	

	NSSortDescriptor *romNameDescriptor=[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
		
	// Set up the 'Sort By' Menu
	NSArray *sortKeys = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Sort Keys" ofType:@"plist"]];
	_sortKeyTitles = [[NSMutableDictionary alloc] initWithCapacity:[sortKeys count]];
	int menuItemIndex = 0;
	for (id nextSortKey in sortKeys) {
		if ([[nextSortKey valueForKey:@"visible"] boolValue]) {
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"by %@",[nextSortKey valueForKey:@"title"]] action:@selector(setGamesControllerSortDescriptors:) keyEquivalent:@""];

			[_sortKeyTitles setObject:nextSortKey forKey:[nextSortKey valueForKey:@"key"]];

			[item setRepresentedObject:[nextSortKey valueForKey:@"key"]];
			[item setTarget:self];		
			[sortGamesMenu insertItem:item atIndex:menuItemIndex];
			
			[item release];
			menuItemIndex++;
		}
	}	
	
	// sorting
	//NSLog(@"sortKey: %@",[[NSUserDefaults standardUserDefaults] objectForKey:@"MLSortKey"]);
	//NSLog(@"defaultsController value: %@",[defaultsController valueForKeyPath:@"values.MLSortKey"]);	
	if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:@"MLSortKey"]) {
		[[NSUserDefaults standardUserDefaults] setObject:@"desc" forKey:@"MLSortKey"];
	} 	
	if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:@"MLSortDescending"]) {
		[[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"MLSortDescending"];
	}	

	[self bind:@"sortKey" toObject:defaultsController withKeyPath:@"values.MLSortKey" options:nil];		
	[self bind:@"sortDescending" toObject:defaultsController withKeyPath:@"values.MLSortDescending" options:nil];		

	// set the sort key title (used in the grid header view)
	[self setValue:[self valueForKeyPath:[NSString stringWithFormat:@"sortKeyTitles.%@.title",[[NSUserDefaults standardUserDefaults] objectForKey:@"MLSortKey"]]] forKey:@"sortKeyTitle"];
	
	[self setGamesPredicate];
	[self updateSortDescriptors];	
	
	[gamesArrayController setSortDescriptors:[NSArray arrayWithObject:romNameDescriptor]];

	[gridHeaderView bind:@"sortDescending" toObject:self withKeyPath:@"sortDescending" options:nil];	
	[gridHeaderView bind:@"orderByKey" toObject:self withKeyPath:@"sortKey" options:nil];	
	[gridHeaderView bind:@"orderByKeyTitle" toObject:self withKeyPath:@"sortKeyTitle" options:nil];		

	[collectionsTreeController prepareContent];

	if ([window respondsToSelector:@selector(setPreferredBackingLocation:)]) {
		[window setPreferredBackingLocation:1];		// NSWindowBackingLocationVideoMemory == 1
	}
	
	[window setContentBorderThickness:34.0 forEdge:NSMinYEdge];
	[window makeKeyAndOrderFront:self];
		
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forceFetch:) name:@"MLRomPathFound" object:nil];	

	if (nil == _parser || ![[_parser valueForKey:@"importing"] boolValue]) {
		NSString *mameVersion = [self mameVersionString];
		if (nil != mameVersion) {
			double d = atof([mameVersion cStringUsingEncoding:NSASCIIStringEncoding]);		
			if (d < 0.117) {
				// User needs a newer MAME
				NSLog(@"Newer version of MAME OS X Required");
			}
			if (![mameVersion isEqualTo:[[NSUserDefaults standardUserDefaults] stringForKey:@"MLLastMAMEVersion"]]) {
				// Need to parse the new --listxml
				//NSLog(@"MAME Library needs to update the game database.");	
				if ([self requestMAMEDataUpdate]) {
					[self importFromMAME:self];
				}
			}
	//		[[NSUserDefaults standardUserDefaults] setValue:mameVersion forKey:@"MLLastMAMEVersion"];
		}
	}	
}

// Opens metadata files sent from Spotlight
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    for (NSString *filename in filenames) {
		if ([[filename pathExtension] isEqualToString:MLMetadataPathExtension]) {
			// NSLog(@"open %@",[[filename lastPathComponent] stringByDeletingPathExtension]);
			
			NSFetchRequest *request = [[self managedObjectModel] fetchRequestFromTemplateWithName:@"gameWithName" substitutionVariables:[NSDictionary dictionaryWithObject:[[filename lastPathComponent] stringByDeletingPathExtension] forKey:@"name"]];
			NSError *error = nil;
			NSArray *games = [[self managedObjectContext] executeFetchRequest:request error:&error];								
			
			if ([games count] > 0) {
				MLGame *game = [games objectAtIndex:0];
				// select the Library item
				[collectionsTreeController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
				NSInteger index = [[availableGamesArrayController arrangedObjects] indexOfObjectIdenticalTo:game];
				
				// NSLog(@"index: %i",index);
				
				if (index != NSNotFound) {
					[browserView setSelectionIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];									
					[browserView scrollIndexToVisible:index];
					[[browserView window] makeFirstResponder:browserView];
				}
			}
		}
	}
}

/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void) dealloc {

	[missingImage release];
	[_sortKeyTitles release];
    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
    [super dealloc];
}

#pragma mark -
// Data Updates
#pragma mark Data Updates

- (IBAction)checkForHistoryDatUpdates:(id)sender
{
//	SUAppcast *historyAppcast = [[SUAppcast alloc] init]; 
//	[historyAppcast setDelegate:self];
//	[historyAppcast fetchAppcastFromURL:[NSURL URLWithString:MLHistoryAppcastURL]];	
}

- (IBAction)getMAMEOSX:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:MAMEOSXURL]];
}

- (BOOL)requestMAMEDataUpdate
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"MAME Library needs to update the game database from MAME OS X"];
	[alert setInformativeText:@"This process may take a few minutes to complete."];
	[alert setAlertStyle:NSWarningAlertStyle];
			
	if ([alert runModal] == NSAlertFirstButtonReturn) {
		//[self importFromMAME:self];
		return YES;
	}	
	
	return NO;
}

- (void)importFromMAMEWithUserInfo:(NSDictionary *)userinfo
{
	if (_parser == nil) {
		_parser = [[MAMEXMLParser alloc] init];
	}
	[_parser importFromMAMEWithUserInfo:userinfo];		
}

- (IBAction)importFromMAME:sender
{
	// save the user's game info
	[self exportUserInfoToPath:[[self applicationSupportFolder] stringByAppendingPathComponent:@"MAME Library User Info.plist"]];

	if (_parser == nil) {
		_parser = [[MAMEXMLParser alloc] init];
	}
	[_parser importFromMAME];	
}

#pragma mark -
// Sorting & Filtering
#pragma mark Sorting & Filtering

- (void)setSortDescending:(id)value
{
	[self willChangeValueForKey:@"sortDescending"];
	[_sortDescending release];
	_sortDescending = [value retain];
	[self didChangeValueForKey:@"sortDescending"];	
	[self updateSortDescriptors];
}

- (IBAction)sortAscending:(id)sender;
{
	[self setSortDescending:[NSNumber numberWithBool:NO]];
}

- (IBAction)sortDescending:(id)sender;
{
	[self setSortDescending:[NSNumber numberWithBool:YES]];
}

- (IBAction)setGamesControllerSortDescriptors:(id)sender
{	
	[self setValue:[sender representedObject] forKey:@"sortKey"];
	[self setValue:[self valueForKeyPath:[NSString stringWithFormat:@"sortKeyTitles.%@.title",[sender representedObject]]] forKey:@"sortKeyTitle"];
	[self updateSortDescriptors];
}

- (IBAction)setRating:(id)sender
{
	NSArray *selectedGames = [availableGamesArrayController selectedObjects];
	for (MLGame *nextGame in selectedGames) {
		[nextGame setValue:[NSNumber numberWithInt:[sender tag]] forKey:@"rating"];
	}
}

- (IBAction)setGamesControllerPredicate:(id)sender
{
	
	if ([sender tag] == 0) {
		[selectedCollection setValue:[NSNumber numberWithBool:NO] forKey:@"showUnavailable"];
	} else {
		[selectedCollection setValue:[NSNumber numberWithBool:YES] forKey:@"showUnavailable"];
	}

	[self setSelectedCollection:selectedCollection];	
	[self setGamesPredicate];	
}

- (IBAction)switchView:(id)sender
{
	if ([[[tabView selectedTabViewItem] identifier] isEqual:@"table"]) {
		// we're viewing the table
		[tabView selectTabViewItemWithIdentifier:@"grid"];		
		return;
	}

	// we're viewing the grid
	[tabView selectTabViewItemWithIdentifier:@"table"];
	[viewModeMatrix display];

}

- (IBAction)toggleArtwork:(id)sender;
{
	BOOL isHidden = [[NSUserDefaults standardUserDefaults] boolForKey:@"MLHideArtworkView"];
	
	[sourceListSplitView setSubview:artworkViewPlaceHolder isCollapsed:!isHidden];
	
	[sourceListSplitView resizeSubviewsWithOldSize:[sourceListSplitView bounds].size];
	[[NSUserDefaults standardUserDefaults] setBool:!isHidden forKey:@"MLHideArtworkView"];
}

- (IBAction)toggleClones:(id)sender
{
	[selectedCollection setValue:[NSNumber numberWithBool:![[selectedCollection valueForKey:@"showClones"] boolValue]] forKey:@"showClones"];
	[self setSelectedCollection:selectedCollection];

	[self setGamesPredicate];
}

- (void)updateSortDescriptors
{
//	NSLog(@"sortKey: %@, sortDescending: %i",[self valueForKey:@"sortKey"],[self valueForKey:@"sortDescending"]);
	NSSortDescriptor *sd;
	NSString *selectorString = [self valueForKeyPath:[NSString stringWithFormat:@"sortKeyTitles.%@.selector",[self valueForKey:@"sortKey"]]];

	// find out if this sort key has a special selector
	if (nil != selectorString) {
		//NSLog(@"selectorString: %@",selectorString);
		sd = [[[NSSortDescriptor alloc] initWithKey:[self valueForKey:@"sortKey"] ascending:![[self valueForKey:@"sortDescending"] boolValue] selector:NSSelectorFromString(selectorString)] autorelease];			
	} else {
		sd = [[[NSSortDescriptor alloc] initWithKey:[self valueForKey:@"sortKey"] ascending:![[self valueForKey:@"sortDescending"] boolValue]] autorelease];	
	}
	
	[self setValue:[NSArray arrayWithObject:sd] forKey:@"sortDescriptors"];
}

- (void)setSelectedCollection:(MLCollection *)collection
{
	MLCollection *oldSelectedCollection = selectedCollection;
	selectedCollection = [collection retain];
	[oldSelectedCollection release];
	
	[self setValue:[selectedCollection predicate] forKey:@"collectionPredicate"];	
	[self setGamesPredicate];
}

- (void)setGamesPredicate
{
	// collections show their contents irrespective of the clones / available setting
//	if ([[selectedCollection valueForKey:@"type"] intValue] != 0) {
	if (nil != collectionPredicate) {
		[gamesArrayController setFilterPredicate:collectionPredicate];		
		return;		
	}
//	}

	[gamesArrayController setFilterPredicate:nil];

//	if (nil != gameListPredicate && nil != showClonesPredicate) {
//		[gamesArrayController setFilterPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:gameListPredicate,showClonesPredicate,nil]]];			
//	} else if (nil != gameListPredicate) {
//		[gamesArrayController setFilterPredicate:gameListPredicate];			
//	} else if (nil != showClonesPredicate) {
//		[gamesArrayController setFilterPredicate:showClonesPredicate];				
//	} else {
//		[gamesArrayController setFilterPredicate:nil];
//	}
	
}

#pragma mark -
// Import & Export
#pragma mark Import & Export

- (IBAction)import:(id)sender
{	
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	[oPanel setRequiredFileType:@"plist"];
    NSString *importDir = [[NSUserDefaults standardUserDefaults] objectForKey:@"MLExportDir"];
    if (!importDir) {	
        importDir = NSHomeDirectory();	 
	}
    [oPanel setAllowsMultipleSelection:NO];	
	
	int runResult = [oPanel runModalForDirectory:importDir file:@""];
	 
	/* if successful, save file under designated name */
	if (runResult == NSOKButton) {						
		[self importUserInfoFromPath:[[oPanel filenames] objectAtIndex:0]];
	}	
	
}

- (BOOL)importUserInfoFromPath:(NSString *)userInfoPath
{
	NSFetchRequest *fetchRequest;
	NSManagedObjectContext *context = [self managedObjectContext];
	//NSPersistentStoreCoordinator *coordinator = [context persistentStoreCoordinator];
	NSError *error;

	NSDictionary *userInfo = [NSDictionary dictionaryWithContentsOfFile:userInfoPath];		
	if (userInfo) {		
		NSArray *userGamesInfo = [userInfo valueForKey:@"games"];		
		if (nil != userGamesInfo && [userGamesInfo count] > 0) {
			NSString *gameName;
			NSArray *fetchedGames;
			MLGame *fetchedGame;			
			for (id userGameInfo in userGamesInfo) {
                gameName = [userGameInfo valueForKey:@"name"];
				if (nil != gameName) {
					//NSLog(@"importing userinfo for: %@",gameName);
					fetchRequest = [[self managedObjectModel] fetchRequestFromTemplateWithName:@"gameWithName" substitutionVariables:[NSDictionary dictionaryWithObject:gameName forKey:@"name"]];
					//NSLog(@"fetchRequest: %@",fetchRequest);
					fetchedGames = [context executeFetchRequest:fetchRequest error:&error];							
					if (([fetchedGames count] > 0) && (fetchedGame = [fetchedGames objectAtIndex:0])) {
						[fetchedGame applyUserGameInfo:userGameInfo];
					}					
				}			
			}		
		}
			
		[self importCollectionsFromUserinfo:userInfo];
		
		return YES;
	}	
	return NO;	
}

- (void)importCollectionsFromUserinfo:(NSDictionary *)userInfo
{
	NSManagedObjectContext *context = [self managedObjectContext];
	NSPersistentStoreCoordinator *coordinator = [context persistentStoreCoordinator];
	//NSError *error;

	NSArray *userCollections = [userInfo valueForKey:@"collections"];					
	//NSLog(@"userCollections: %@",userCollections);
	if (nil != userCollections && [userCollections count] > 0) {			
		NSEnumerator *userCollectionsEnu = [userCollections objectEnumerator];
		NSDictionary *userCollectionInfo;
		while ((userCollectionInfo = [userCollectionsEnu nextObject])) {
		
			MLCollection *collection = nil;
			if (nil != [userCollectionInfo valueForKey:@"objectID"]) {
				NSLog(@"%@",[userCollectionInfo valueForKey:@"objectID"]);
				NSManagedObjectID *objectID = [coordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:[userCollectionInfo valueForKey:@"objectID"]]];
				if (nil != objectID) {
					collection = (MLCollection *)[context objectWithID:objectID];	
				}				
			}
			if (nil == collection) {
				collection = [NSEntityDescription insertNewObjectForEntityForName:@"collection" inManagedObjectContext:context];		
			}
						
			[collection applyUserCollectionInfo:userCollectionInfo];
			NSLog(@"collection: %@",collection);
		}
		[collectionsArrayController fetch:self];
	}			
}

- (IBAction)export:(id)sender
{

	NSSavePanel *sp;
	int runResult;
	 
	/* create or get the shared instance of NSSavePanel */
	sp = [NSSavePanel savePanel];
	 
	/* set up new attributes */
	//	[sp setAccessoryView:newView];
	[sp setRequiredFileType:@"plist"];
	 
    NSString *exportDir = [[NSUserDefaults standardUserDefaults] objectForKey:@"MLExportDir"];
    if (!exportDir) {	
        exportDir = NSHomeDirectory();	 
	}
	 
	/* display the NSSavePanel */
	runResult = [sp runModalForDirectory:exportDir file:@"MAME Library User Info.plist"];
	 
	/* if successful, save file under designated name */
	if (runResult == NSOKButton) {						
		NSString *exportPath = [sp filename];		
		
		if ([self exportUserInfoToPath:exportPath]) {
			exportDir = [exportPath stringByDeletingLastPathComponent];		
			[[NSUserDefaults standardUserDefaults] setObject:exportDir forKey:@"MLExportDir"];
		}
	}	

}

- (NSDictionary *)userInfoFromManagedObjectContext:(NSManagedObjectContext *)context
{
	// construct a fetch request to find all of the games which the user has added info for
	NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
	NSFetchRequest *fetchRequest;
	NSError *error;
	
	fetchRequest = [model fetchRequestTemplateForName:@"gamesWithUserInfo"];		
	NSArray *games = [context executeFetchRequest:fetchRequest error:&error];		

//	NSLog(@"fetchRequest: %@",fetchRequest);
//	NSLog(@"gamesWithUserInfo request games:%@",games);
	
	NSEnumerator *enu = [games objectEnumerator];
	id nextGame;
	
	NSMutableArray *userGamesInfo = [NSMutableArray arrayWithCapacity:[games count]];
	
	while (nextGame = [enu nextObject]) {
		NSDictionary *userGameInfo = [nextGame userGameInfo];
		if (nil != userGameInfo) {
			[userGamesInfo addObject:userGameInfo];
		}
	}
	
	NSMutableArray *collectionsInfo = [NSMutableArray array];
	if (nil != [[model entitiesByName] valueForKey:@"collection"]) {

		NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
		[fetchRequest setEntity:[[model entitiesByName] valueForKey:@"collection"]];
		NSError *error;
		NSArray *collections = [context executeFetchRequest:fetchRequest error:&error];				
		NSEnumerator *collectionsEnu = [collections objectEnumerator];
		MLCollection *nextCollection;
		while (nextCollection = [collectionsEnu nextObject]) {
			[collectionsInfo addObject:[nextCollection dictionaryRepresentation]];
		}		
	}

	return [NSDictionary dictionaryWithObjectsAndKeys:userGamesInfo,@"games",collectionsInfo,@"collections",nil];
}

- (BOOL)exportUserInfoToPath:(NSString *)userInfoPath
{
	NSDictionary *userinfo = [self userInfoFromManagedObjectContext:[self managedObjectContext]];	
	return [userinfo writeToFile:userInfoPath atomically:YES];		
}

#pragma mark -
// Editing Smart Collections
#pragma mark Editing Smart Collections

- (IBAction)editSmartCollection:(id)sender {
	
	if (nil == predicateEditor) {
		[NSBundle loadNibNamed:@"Collection Editor" owner:self];
	}
	
	predicateEditorModalSession = [NSApp beginModalSessionForWindow:[predicateEditor window]];
	[NSApp runModalSession:predicateEditorModalSession];
	
}	

- (IBAction)closeCollectionEditor:(id)sender
{
	[NSApp endModalSession:predicateEditorModalSession];
	[[predicateEditor window] close];
	
	if ([sender tag] == 1) {
		NSLog(@"predicate: %@",[predicateEditor objectValue]);		
	}
}

#pragma mark -
// Misc Menus Items
#pragma mark Misc Menus Items

- (IBAction)launchSelectedGame:(id)sender {
//	NSLog(@"launchSelectedGame");
	NSArray *availableGames = [availableGamesArrayController selectedObjects];		
	if ([availableGames count] > 0) {
		MLGame *game = [availableGames objectAtIndex:0];		
		[self launchGame:game];		
	}

}

- (IBAction)findScreenshots:(id)sender {
	NSArray *selectedObjects = [availableGamesArrayController selectedObjects];
	if ([selectedObjects count] == 0) {
		selectedObjects = [availableGamesArrayController arrangedObjects];
	}
	
	[selectedObjects makeObjectsPerformSelector:@selector(searchForScreenShot)];
	[gamesArrayController rearrangeObjects];
	[browserView display];
}

- (IBAction)findNewRoms:(id)sender {

	// empty the metadata folder
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *metadataFolderContents = [fileManager contentsOfDirectoryAtPath:MLMetadataPath error:nil];
    
    for (NSString *path in metadataFolderContents) {
		if ([[path pathExtension] isEqualToString:MLMetadataPathExtension]) {
			[fileManager removeItemAtPath:path error:nil];
		}        
    }
	
	NSArray *selectedObjects;

	selectedObjects = [availableGamesArrayController selectedObjects];
	if ([selectedObjects count] == 0) {
				
		selectedObjects = [self allGamesInStore];
	}

	[selectedObjects makeObjectsPerformSelector:@selector(searchForROM)];
	
	[gamesArrayController rearrangeObjects];
	[browserView display];


//	NSString *ROMPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"MLROMsPath"];
//	if (![[NSFileManager defaultManager] fileExistsAtPath:ROMPath]) {
//		return;
//	}
//
//	NSDirectoryEnumerator *enu = [[NSFileManager defaultManager] enumeratorAtPath:ROMPath];
//	id nextFile;
//	
//	while (nextFile = [enu nextObject]) {
//		if ([[[nextFile pathExtension] lowercaseString] isEqualToString:@"zip"]) {
//			NSError *error;			
//			NSFetchRequest *fetchRequest = [[self managedObjectModel] fetchRequestFromTemplateWithName:@"gameWithName" substitutionVariables:[NSDictionary dictionaryWithObject:[nextFile stringByDeletingPathExtension] forKey:@"name"]];
//			NSArray *games = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];				
//			if ([games count] > 0) {
//				[[games objectAtIndex:0] setValue:[ROMPath stringByAppendingPathComponent:nextFile] forKey:@"romPath"];
//			}	
//		}		
//	}
	
//	[self forceFetch:self];
		
}

- (IBAction)showFAQ:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:MLFAQURL]];
}

- (IBAction)showReleaseNotes:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:MLReleaseNotesURL]];
}

- (IBAction)visitWebsite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:MLWebsiteURL]];	
}

- (IBAction)revealInFinder:(id)sender
{
	NSArray *selectedObjects = [availableGamesArrayController selectedObjects];
	
	if ([selectedObjects count] > 0) {
		[[selectedObjects objectAtIndex:0] revealInFinder:sender];
	}
	
}

- (NSString *)mameVersionString
{
	NSString *mamePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"MLMAMEPath"];
	BOOL isDirectory = NO;
	BOOL exists = NO;
	exists = [[NSFileManager defaultManager] fileExistsAtPath:mamePath isDirectory:&isDirectory];
    
    if (!exists) {
        return nil;
    }
    
    if (isDirectory) {
        // MAME OS X
        NSString *mameInfoPath = [[[NSUserDefaults standardUserDefaults] stringForKey:@"MLMAMEPath"] stringByAppendingPathComponent:@"Contents/Info.plist"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:mameInfoPath]) {
            NSDictionary *mameInfoDict = [NSDictionary dictionaryWithContentsOfFile:mameInfoPath];
            return [mameInfoDict valueForKey:@"CFBundleShortVersionString"];
        }        
    } else {
        // SDLMame
//        [NSArray *args = [NSArray arrayWithObject:@""];
//        NSTask *task = [NSTask launchedTaskWithLaunchPath:mamePath arguments:args];
//        [task waitUntilExit];
        // TODO: get mame version using NSTask
    }
    

	return nil;	
}

- (IBAction)getInfo:sender
{
	if (nil == inspectorPanel) {
		[NSBundle loadNibNamed:@"Inspector" owner:self];
	}
	[inspectorPanel orderFront:sender];
}

- (IBAction)toggleBrowserViewTitles:(id)sender {
	if ([browserView cellsStyleMask] & 4) {
		[browserView setCellsStyleMask:([browserView cellsStyleMask] & 11)];
		return;
	}
	
	[browserView setCellsStyleMask:([browserView cellsStyleMask] | 4)];	
}

- (IBAction) showDebugWindow:(id)sender {
	[debugWindow makeKeyAndOrderFront:self];
}

#pragma mark -
// Core Data
#pragma mark Core Data

/**
    Returns the support folder for the application, used to store the Core Data
    store file.  This code uses a folder named "MAME_Library" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportFolder {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"MAME_Library"];
}

- (NSString *)cacheFolder {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"MAME Library"];
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
	
	NSString *dataModelName = [NSString stringWithFormat:@"MAME_Library_DataModel%i",MLDataModelVersion];
	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:dataModelName ofType:@"mom"]];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
    
    return managedObjectModel;
}

- (NSManagedObjectModel *)managedObjectModelVersion:(int)version {

	NSString *dataModelName = [NSString stringWithFormat:@"MAME_Library_DataModel%i",version];
	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:dataModelName ofType:@"mom"]];
    NSManagedObjectModel *managedObjectModelVersion = [[[NSManagedObjectModel alloc] initWithContentsOfURL:url] autorelease];
    
    return managedObjectModelVersion;
}


/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The folder for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {

//	NSLog(@"persistentStoreCoordinator");

    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSURL *importUrl;	
    NSError *error;
	NSDictionary *storeMetaData;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"MAME_Library.ml_sqlite"]];
	
	storeMetaData = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:url error:&error];
	// here is where we need to jump somewhere else if the store is out of date	
	int dataModelVersion = [[storeMetaData objectForKey:@"MLDataModelVersion"] intValue];
	if (dataModelVersion == 0) {
		dataModelVersion = 1;		// start numbering at 1
	}
	if (dataModelVersion < MLDataModelVersion) {
		if (![self requestMAMEDataUpdate]) {
			[NSApp terminate:self];	// quit
		}	
	
		// move the old store aside, open a new store
		NSString *importPath = [applicationSupportFolder stringByAppendingPathComponent: @"MAME_Library.previous.ml_sqlite"];
	    importUrl = [NSURL fileURLWithPath:importPath];	
		if ([[NSFileManager defaultManager] fileExistsAtPath:importPath]) {
			[[NSFileManager defaultManager] removeItemAtPath:importPath error:nil];
		}
		[[NSFileManager defaultManager] moveItemAtPath:[url path] toPath:[importUrl path] error:nil];		
		//NSLog(@"Move: %@ -> %@",url,importUrl);
	}
	
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    
	
	if (dataModelVersion < MLDataModelVersion) {
		// merge the old data into the new model
		importStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModelVersion:dataModelVersion]];
		if (![importStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:importUrl options:nil error:&error]){
			[[NSApplication sharedApplication] presentError:error];
		}		
		
        NSManagedObjectContext *importContext = [[NSManagedObjectContext alloc] init];
        [importContext setPersistentStoreCoordinator: importStoreCoordinator];
		
		NSDictionary *userinfo = [self userInfoFromManagedObjectContext:importContext];
		//NSLog(@"importContext userinfo: %@",userinfo);
		
		[importContext release];
		[importStoreCoordinator release];		
		
		if (nil != userinfo) {
			[self importFromMAMEWithUserInfo:userinfo];
		} else {
			[self importFromMAME:self];		
		}				
		
	}	
	
	[persistentStoreCoordinator setMetadata:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:MLDataModelVersion] forKey:@"MLDataModelVersion"] forPersistentStore:[persistentStoreCoordinator persistentStoreForURL:url]];

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
		[managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];	// user changes get perference
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

- (IBAction) tableViewDoubleClick:(id)sender {
	
	if ([sender clickedRow] > 0) {
		NSArray *availableGames = [availableGamesArrayController arrangedObjects];	
		MLGame *game = [availableGames objectAtIndex:[sender clickedRow]];		
		[self launchGame:game];		
	}

}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
	if (tableColumn == imagesTableColumn) {
//		NSLog(@"switchView");
		[self switchView:self];
	}
}
 
- (IBAction) saveAction:(id)sender {

//	NSLog(@"saving defaultsController value: %@",[defaultsController valueForKeyPath:@"values.MLSortKey"]);

	// save the user's game info
	[self exportUserInfoToPath:[[self applicationSupportFolder] stringByAppendingPathComponent:@"MAME Library User Info.plist"]];

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
	
}


/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return TRUE;
}

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

- (IBAction)forceFetch:(id)sender;
{
//	NSLog(@"forceFetch");
	[gamesArrayController fetch:sender];
	[gamesArrayController rearrangeObjects];
}

- (NSArray *)allGamesInStore
{
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"game" inManagedObjectContext:[self managedObjectContext]];

	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	
	NSError *error = nil;
	NSArray *games = [[self managedObjectContext] executeFetchRequest:request error:&error];		
	
	return games;	
}

- (NSArray *)gamesWithRomPath
{
	NSFetchRequest *request = [[self managedObjectModel] fetchRequestTemplateForName:@"gamesWithRomPath"];
	NSError *error = nil;
	NSArray *games = [[self managedObjectContext] executeFetchRequest:request error:&error];		
	
	return games;		
}

- (void)getGameTitles {
	// NSString *list = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"list" ofType:@"txt"]];
		
}

#pragma mark -
// TableViewDataSource methods
#pragma mark MUPhotoViewDelegate methods

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	NSArray *availableGames = [availableGamesArrayController arrangedObjects];
	NSArray *draggedGames = [availableGames objectsAtIndexes:rowIndexes];
	[pboard declareTypes:[NSArray arrayWithObject:MLGamesPasteboardType] owner:self];
	[pboard setData:[self pasteboardDataForItems:draggedGames] forType:MLGamesPasteboardType];
	return YES;
}

#pragma mark -
// IKImageBrowserView methods
#pragma mark IKImageBrowserView delegate

- (void) imageBrowser:(IKImageBrowserView *) aBrowser cellWasDoubleClickedAtIndex:(NSUInteger) index;
{
	NSArray *availableGames = [availableGamesArrayController arrangedObjects];	
	MLGame *game = [availableGames objectAtIndex:index];
	
	[self launchGame:game];
}

- (NSUInteger) imageBrowser:(IKImageBrowserView *) aBrowser writeItemsAtIndexes:(NSIndexSet *) itemIndexes toPasteboard:(NSPasteboard *)pasteboard;
{
	NSArray *availableGames = [availableGamesArrayController arrangedObjects];
	NSArray *draggedGames = [availableGames objectsAtIndexes:itemIndexes];
	[pasteboard declareTypes:[NSArray arrayWithObject:MLGamesPasteboardType] owner:self];
	[pasteboard setData:[self pasteboardDataForItems:draggedGames] forType:MLGamesPasteboardType];
	return [itemIndexes count];	
}

- (void) imageBrowser:(IKImageBrowserView *) aBrowser removeItemsAtIndexes:(NSIndexSet *) indexes;
{
	if ([self canRemove]) {
		NSArray *selectedGames = [availableGamesArrayController selectedObjects];
		[selectedCollection removeGames:selectedGames];
	}
}

#pragma mark -
// MUPhotoViewDelegate methods
#pragma mark MUPhotoViewDelegate methods

- (NSData *)pasteboardDataForItems:(NSArray *)items
{	
	NSMutableArray *gamesPasteboardData = [NSMutableArray arrayWithCapacity:[items count]];
	NSEnumerator *selectedGamesEnu = [items objectEnumerator];
	MLGame *nextGame;
	while (nextGame = [selectedGamesEnu nextObject]) {
		[gamesPasteboardData addObject:[nextGame valueForKey:@"name"]];
	}		
	return [NSArchiver archivedDataWithRootObject:gamesPasteboardData];
}

- (void)applicationWillBecomeActive:(NSNotification *)aNotification
{
	[browserView display];
}

- (BOOL)canRemove
{
	if ([[selectedCollection valueForKey:@"type"] intValue] != 0) {
		return YES;
	}

	return NO;
}

//- (NSData *)pasteboardDataForItems:(NSArray *)items
//{	
//	NSMutableArray *gamesPasteboardData = [NSMutableArray arrayWithCapacity:[items count]];
//	NSEnumerator *selectedGamesEnu = [items objectEnumerator];
//	MLGame *nextGame;
//	while (nextGame = [selectedGamesEnu nextObject]) {
//		[gamesPasteboardData addObject:[nextGame valueForKey:@"name"]];
//	}		
//	return [NSArchiver archivedDataWithRootObject:gamesPasteboardData];
//}
//
//- (NSData *)photoView:(MUPhotoView *)view pasteboardDataForPhotoAtIndex:(unsigned)index dataType:(NSString *)type
//{
//	if ([type isEqualToString:MLGamePasteboardType]) {
//		NSArray *availableGames = [availableGamesArrayController arrangedObjects];
//		return [[availableGames objectAtIndex:index] pasteboardData];
//	} else if ([type isEqualToString:MLGamesPasteboardType]) {
//		NSArray *selectedGames = [availableGamesArrayController selectedObjects];
//		return [self pasteboardDataForItems:selectedGames];
//	}
//	
//	return [NSData data];
//}

- (void)launchGame:(MLGame *)game
{
	if (mameTask != nil) {
		[mameTask terminate];
		[mameTask release];
	}		
	
	NSString *romPath = [game valueForKey:@"romPath"];
	[game setValue:[NSDate date] forKey:@"lastplayed"];
	
	int playcount = 0;
	if (nil != [game valueForKey:@"playcount"]) {
		playcount = [[game valueForKey:@"playcount"] intValue];
	}
	playcount++;
	[game setValue:[NSNumber numberWithInt:playcount] forKey:@"playcount"];
	
	NSString *mamePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"MLMAMEPath"];
	BOOL isDirectory = NO;
	BOOL exists = NO;
	exists = [[NSFileManager defaultManager] fileExistsAtPath:mamePath isDirectory:&isDirectory];
	
    NSMutableArray *args = [NSMutableArray arrayWithCapacity:3];
    
    BOOL fullscreen = [[NSUserDefaults standardUserDefaults] boolForKey:@"MLLaunchFullScreen"];
    
	if (exists && isDirectory) {
        // MAME OS X
		mamePath = [NSString stringWithFormat:@"%@/Contents/MacOS/MAME OS X",mamePath];
        
        [args addObject:@"-Game"];
        [args addObject:[[romPath lastPathComponent] stringByDeletingPathExtension]];        
        
        if (fullscreen) {
            [args addObject:@"-FullScreen"];
            [args addObject:@"YES"];		
        }
	} else {
        // SDLMame
        NSString *romsPath = [[NSUserDefaults standardUserDefaults] valueForKey:@"MLROMsPath"];
        if (nil != romsPath) {
            [args addObject:@"-rompath"];
            [args addObject:[romPath stringByDeletingLastPathComponent]];    
            [args addObject:[[romPath lastPathComponent] stringByDeletingPathExtension]];
        }
        
        if (!fullscreen) {        
            [args addObject:@"-window"];            
        }        
    }
    
    NSLog(@"Command: %@ Args: %@", mamePath, args);
    
    mameTask = [[NSTask launchedTaskWithLaunchPath:mamePath arguments:args] retain];            	
    
	// register for 'game ended' notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findScreenshots:) name:@"NSTaskDidTerminateNotification" object:nil];	
	
	// save the user's game info
	[self exportUserInfoToPath:[[self applicationSupportFolder] stringByAppendingPathComponent:@"MAME Library User Info.plist"]];	
}

#pragma mark -
// Menu Item Validation
#pragma mark Menu Item Validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem == switchViewMenuItem) {
	if ([[[tabView selectedTabViewItem] identifier] isEqual:@"table"]) {
		// we're viewing the table
		[switchViewMenuItem setTitle:@"Show As Screenshots"];
		} else {
		[switchViewMenuItem setTitle:@"Show As List"];
		}
		return TRUE;	
		
	} else if ([menuItem action] == @selector(toggleBrowserViewTitles:)) {			
		[menuItem setState:NSOffState];
		if ([browserView cellsStyleMask] & 4) {
			[menuItem setState:NSOnState];
		}
		if ([[[tabView selectedTabViewItem] identifier] isEqual:@"table"]) {
			return FALSE;
		}
	} else if ([menuItem action] == @selector(revealInFinder:)) {
		NSArray *selectedObjects;
		if (selectedObjects = [availableGamesArrayController selectedObjects]) {
			if ([selectedObjects count] > 0 && nil != [[selectedObjects objectAtIndex:0] valueForKey:@"romPath"]) {
				return TRUE;
			}
		}
		return FALSE;
	} else if ([menuItem action] == @selector(setGamesControllerSortDescriptors:)) {
		NSString *currentSortKey = [[[availableGamesArrayController sortDescriptors] objectAtIndex:0] key];
		[menuItem setState:NSOffState];
		if ([[menuItem representedObject] isEqual:currentSortKey]) {
			[menuItem setState:NSOnState];
		}		
	} else if ([menuItem action] == @selector(setGamesControllerPredicate:)) {
		[menuItem setState:NSOffState];
		if ([menuItem tag] == 0) {
			// Show Available Games
			if (![[selectedCollection valueForKey:@"showUnavailable"] boolValue]) {			
				[menuItem setState:NSOnState];
			}
		}
		if ([menuItem tag] == 2) {
			// Show All Games
			// Show Available Games
			if ([[selectedCollection valueForKey:@"showUnavailable"] boolValue]) {			
				[menuItem setState:NSOnState];
			}
		}
		// switch the menu item off if a folder is selected
		if ([[selectedCollection valueForKey:@"type"] intValue] == 1 || [[selectedCollection valueForKey:@"type"] intValue] == 2) {
			return FALSE;
		}
	} else if ([menuItem action] == @selector(editSmartCollection:)) {
		// switch the menu item off unless a smart collection is selected
		// NSLog(@"%@ type: %@",[selectedCollection valueForKey:@"title"],[selectedCollection valueForKey:@"type"]);
		if ([[selectedCollection valueForKey:@"type"] intValue] == 3) {
			return TRUE;
		}	
		return FALSE;
	} else if ([menuItem action] == @selector(toggleClones:)) {
		if ([[selectedCollection valueForKey:@"showClones"] boolValue]) {
			[menuItem setTitle:@"Hide Clones"];
		} else {
			[menuItem setTitle:@"Show Clones"];
		}
		// switch the menu item off if a folder is selected
		if ([[selectedCollection valueForKey:@"type"] intValue] == 1 || [[selectedCollection valueForKey:@"type"] intValue] == 2) {
			return FALSE;
		}		
	} else if ([menuItem action] == @selector(toggleArtwork:)) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MLHideArtworkView"]) {
			[menuItem setTitle:@"Show Artwork"];
		} else {
			[menuItem setTitle:@"Hide Artwork"];		
		}				
	} else if ([menuItem action] == @selector(sortAscending:)) {
		[menuItem setState:NSOffState];
		if ([[[availableGamesArrayController sortDescriptors] objectAtIndex:0] ascending]) {
			[menuItem setState:NSOnState];
		}
	} else if ([menuItem action] == @selector(sortDescending:)) {
		[menuItem setState:NSOffState];
		if (![[[availableGamesArrayController sortDescriptors] objectAtIndex:0] ascending]) {
			[menuItem setState:NSOnState];
		}					
	} else if ([menuItem action] == @selector(launchSelectedGame:)) {
		if ([[availableGamesArrayController selectionIndexes] count] == 0) {
			return FALSE;
		}		
	} else if ([menuItem action] == @selector(setRating:)) {
		[menuItem setState:NSOffState];		
		NSArray *selectedGames = [availableGamesArrayController selectedObjects];
		if ([selectedGames count] == 0) {
			return FALSE;
		} else if ([selectedGames count] > 0) {
			BOOL allTheSame = TRUE;
			float rating = round([[[selectedGames objectAtIndex:0] valueForKey:@"rating"] floatValue]);
			NSEnumerator *selectedGamesEnu = [selectedGames objectEnumerator];
			MLGame *nextGame;
			while (nextGame = [selectedGamesEnu nextObject]) {
				if (rating != round([[nextGame valueForKey:@"rating"] floatValue])) {
					allTheSame = FALSE;
				}
			}
			if (allTheSame) {
				if (rating == [menuItem tag]) {
					[menuItem setState:NSOnState];
				}
			}
		}
	} else if ([menuItem action] == @selector(delete:)) {
		NSLog(@"validateMenuItem delete:");
		return [self canRemove];
	}

	return TRUE;
}

#pragma mark -
// SUAppcastDelegate methods
#pragma mark SUAppcastDelegate methods (History .dat)

//- (void)appcastDidFinishLoading:(SUAppcast *)ac
//{
//	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:MLLastHistoryCheckTimeKey];
//
//	NSArray *items = [ac items];
//	
//	NSSortDescriptor *versionStringDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"versionString" ascending:NO] autorelease]; 
//	
//	[items sortedArrayUsingDescriptors:[NSArray arrayWithObject:versionStringDescriptor]];
//
//	if ([items count] > 0) {
//		id nextItem = [items objectAtIndex:0];
//		if ([[nextItem description] isEqualToString:@"mamehistory"]) {
//			if (![[nextItem versionString] isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"MLLastHistoryDatVersion"]]) {
//				NSLog(@"title: %@, versionString: %@, fileURL: %@",[nextItem title],[nextItem versionString],[nextItem fileURL]);
//				// NSURLDownload *downloader = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:[nextItem fileURL]] delegate:self];					
//			}
//		}
//	}
//}
//
//- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)name
//{
//	// If name ends in .txt, the server probably has a stupid MIME configuration. We'll give
//	// the developer the benefit of the doubt and chop that off.
//	if ([[name pathExtension] isEqualToString:@"txt"]) {
//		name = [name stringByDeletingPathExtension];
//	}
//	
//	historyDownloadPath = [[self cacheFolder] stringByAppendingPathComponent:name];
//	[download setDestination:historyDownloadPath allowOverwrite:YES];
//}
//
//- (void)downloadDidFinish:(NSURLDownload *)download
//{
//	NSLog(@"downloadDidFinish: %@",download);
//
//	SUUnarchiver *unarchiver = [[SUUnarchiver alloc] init];
//	[unarchiver setDelegate:self];
//	[unarchiver unarchivePath:historyDownloadPath];
//	
//	[download release];		
//}
//
//- (void)unarchiverDidFinish:(SUUnarchiver *)ua
//{
//	[ua autorelease];
//	NSString *newHistoryPath = [[[historyDownloadPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"history"] stringByAppendingPathExtension:@"dat"];
//	NSLog(@"new history.dat downloaded & extracted: %@",newHistoryPath);
//	_historyParser = [[MLHistoryParser alloc] init];
//	[_historyParser parseHistoryDataAtPath:newHistoryPath];
//}

@end
