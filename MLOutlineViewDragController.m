//
//  MLOutlineViewDragController.m
//  MAME Library
//
//  Created by Johnnie Walker on 16/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "constants.h"
#import "MLOutlineViewDragController.h"
#import "ImageAndTextCell.h"
#import "MLCollection.h"
#import "NSTreeController-DMExtensions.h"
//#import "NSTreeController_Extensions.h"

@implementation MLOutlineViewDragController

- (void)awakeFromNib {	
	
	dragType = [NSArray arrayWithObjects: MLCollectionPasteboardType, MLGamePasteboardType, MLGamesPasteboardType, nil];
	
	[ dragType retain ]; 
	
	[ treeTable registerForDraggedTypes:dragType ];
	NSSortDescriptor* sortDesc = [[NSSortDescriptor alloc] initWithKey:@"sequence" ascending:YES];
	[groupTreeControl setSortDescriptors:[NSArray arrayWithObject: sortDesc]];
	[ sortDesc release ];
	
	NSTableColumn* column = [[treeTable tableColumns] objectAtIndex:0];
	
	ImageAndTextCell* cell = [[[ImageAndTextCell alloc] init] autorelease];	
	[column setDataCell: cell];		
	
	//_collectionImages = [[NSArray alloc] initWithObjects:[NSImage imageNamed:@"Library16"],[NSImage imageNamed:@"Folder16"],[NSImage imageNamed:@"Collection16"],[NSImage imageNamed:@"SmartCollection16"],nil];
	_collectionImages = [[NSArray alloc] initWithObjects:[NSImage imageNamed:@"Library24"],[NSImage imageNamed:@"Folder24"],[NSImage imageNamed:@"Collection24"],[NSImage imageNamed:@"SmartCollection24"],nil];	

	// Library collection
	NSFetchRequest *fetchRequest = [[[[[NSApp delegate] managedObjectContext] persistentStoreCoordinator] managedObjectModel] fetchRequestTemplateForName:@"libraryCollection"];		
	NSError *error;
	NSArray *collections = [[[NSApp delegate] managedObjectContext] executeFetchRequest:fetchRequest error:&error];			
	NSManagedObjectContext *context = [[NSApp delegate] managedObjectContext];
//	NSLog(@"collections: %@",collections);
	if ([collections count] < 1) {
		_libraryCollection = [NSEntityDescription insertNewObjectForEntityForName:@"collection" inManagedObjectContext:context];		
		[_libraryCollection setValue:[NSNumber numberWithInt:0] forKey:@"type"];
		[_libraryCollection setValue:[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:@"MLShowClones"]] forKey:@"showClones"];
		[_libraryCollection setValue:[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:@"MLShowAllGames"]] forKey:@"showUnavailable"];
		[_libraryCollection setValue:@"name != nil" forKey:@"predicateString"];	
		[_libraryCollection setValue:@"Library" forKey:@"title"];							
	}
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"MLDidImportDefaultSmartCollections"]) {
	
		NSArray *defaultSmartCollections = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Default Smart Collections" ofType:@"plist"]];
		NSEnumerator *defaultSmartCollectionsEnu = [defaultSmartCollections objectEnumerator];
		NSDictionary *nextDefaultSmartCollectionDict;
		
		int sequence = MLTreeInterval;
		
		while (nextDefaultSmartCollectionDict = [defaultSmartCollectionsEnu nextObject]) {
			MLCollection *nextDefaultSmartCollection = [NSEntityDescription insertNewObjectForEntityForName:@"collection" inManagedObjectContext:context];			
			[nextDefaultSmartCollection setValue:[NSNumber numberWithInt:3] forKey:@"type"];
			[nextDefaultSmartCollection setValue:[NSNumber numberWithInt:sequence] forKey:@"sequence"];		
			
			[nextDefaultSmartCollection setValue:[nextDefaultSmartCollectionDict valueForKey:@"predicate"] forKey:@"predicateString"];		
			[nextDefaultSmartCollection setValue:[nextDefaultSmartCollectionDict valueForKey:@"title"] forKey:@"title"];		
			
			if (nil != [nextDefaultSmartCollectionDict valueForKey:@"limit"]) {
				[nextDefaultSmartCollection setValue:[nextDefaultSmartCollectionDict valueForKey:@"limit"] forKey:@"limit"];
			}

			if (nil != [nextDefaultSmartCollectionDict valueForKey:@"sortDescending"]) {
				[nextDefaultSmartCollection setValue:[nextDefaultSmartCollectionDict valueForKey:@"sortDescending"] forKey:@"sortDescending"];
			}

			if (nil != [nextDefaultSmartCollectionDict valueForKey:@"sortBy"]) {
				[nextDefaultSmartCollection setValue:[nextDefaultSmartCollectionDict valueForKey:@"sortBy"] forKey:@"sortBy"];
			}
			
			sequence += MLTreeInterval;
		}
		
		[context processPendingChanges];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MLDidImportDefaultSmartCollections"];
	}
	
//	[treeTable setAutosaveExpandedItems:YES];
}	

-(void)setSelectedCollectionsIndexPaths:(NSArray *)indexPaths;
{
//	NSLog(@"setSelectedCollectionsIndexPaths: %@",indexPaths);
	NSArray *oldIndexPaths = _selectedCollectionsIndexPaths;
	_selectedCollectionsIndexPaths = [indexPaths retain];
	[oldIndexPaths release];

	NSArray *selectedObjects = [groupTreeControl selectedObjects];
	MLCollection *selectedCollection = [selectedObjects objectAtIndex:0];

//	NSLog(@"collection predicate: %@",[selectedCollection valueForKey:@"predicate"]);
	[[NSApp delegate] setValue:selectedCollection forKey:@"selectedCollection"];
}

- (IBAction)addNewCollection:(id)sender;
{
	MLCollection *newCollection = [self newCollection];
	[groupTreeControl setSelectedObjects:[NSArray arrayWithObject:newCollection]];
	int row = [treeTable selectedRow];	
//	NSLog(@"row: %i",row);
	[treeTable editColumn:0 row:row withEvent:nil select:YES];
}

- (MLCollection *)newCollection
{
	NSManagedObjectContext *context = [[NSApp delegate] managedObjectContext];
	MLCollection *collection = [NSEntityDescription insertNewObjectForEntityForName:@"collection" inManagedObjectContext:context];		
	[collection setValue:[NSNumber numberWithInt:2] forKey:@"type"];
	[collection setValue:@"untitled collection" forKey:@"title"];		
	[collection setValue:[NSNumber numberWithInt:(([treeTable numberOfRows]+1) * MLTreeInterval)] forKey:@"sequence"];
	[context processPendingChanges];
	return collection;	
}

- (IBAction)addNewSmartCollection:(id)sender;
{
	NSManagedObjectContext *context = [[NSApp delegate] managedObjectContext];
	MLCollection *collection = [NSEntityDescription insertNewObjectForEntityForName:@"collection" inManagedObjectContext:context];		
	[collection setValue:[NSNumber numberWithInt:3] forKey:@"type"];
	[collection setValue:@"untitled smart collection" forKey:@"title"];				
	[context processPendingChanges];
	[groupTreeControl setSelectedObjects:[NSArray arrayWithObject:collection]];	
}

- (IBAction)addNewFolder:(id)sender;
{
	NSManagedObjectContext *context = [[NSApp delegate] managedObjectContext];
	MLCollection *collection = [NSEntityDescription insertNewObjectForEntityForName:@"collection" inManagedObjectContext:context];		
	[collection setValue:[NSNumber numberWithInt:1] forKey:@"type"];
	[collection setValue:@"untitled folder" forKey:@"title"];	
	[context processPendingChanges];
	[groupTreeControl setSelectedObjects:[NSArray arrayWithObject:collection]];				
}

- (int)typeForShadowItem:(id)item
{
	NSNumber *type;
	if (type = [[item observedObject] valueForKey:@"type"]) {
		return [type intValue];			
	}
	return -1;
}

-(BOOL)canRemove
{
	NSArray *selectedObjects = [groupTreeControl selectedObjects];	
	
	if ([selectedObjects count] > 0) {
		MLCollection *selectedCollection = [selectedObjects objectAtIndex:0];
		return ![selectedCollection isEqual:_libraryCollection];
	}
	
	return NO;
}

- (IBAction)delete:(id)sender
{

	NSArray *selectedObjects = [groupTreeControl selectedObjects];	
	
	if ([selectedObjects count] > 0) {
		MLCollection *selectedCollection = [selectedObjects objectAtIndex:0];		
		int selectedRow = [treeTable selectedRow];
		selectedRow--;
		if (selectedRow < 0) {
			selectedRow = 0;
		}
		[treeTable selectRow:selectedRow byExtendingSelection:NO];				
		[[selectedCollection managedObjectContext] deleteObject:selectedCollection];
	}
	
}

//------------------------------------
#pragma mark NSOutlineView delegate methods
//------------------------------------

//- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object
//{
//	NSManagedObjectContext *context = [[NSApp delegate] managedObjectContext];
//	NSPersistentStoreCoordinator *coordinator = [context persistentStoreCoordinator];
//	NSManagedObjectID *objectID = [coordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:object]];
//	NSLog(@"arrangedIndexPathForObject: %@ (%@)",[groupTreeControl arrangedIndexPathForObject:[context objectWithID:objectID]],[[context objectWithID:objectID] valueForKey:@"title"]);
//	NSLog(@"numberOfRows: %i",[treeTable numberOfRows]);
//	return [groupTreeControl outlineItemForObject:[context objectWithID:objectID]];
//}
//
//- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item
//{
//	return [[[[item observedObject] objectID] URIRepresentation] absoluteString];
//}

// Used to add the image icons to the cell
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item 
{    
	if ([[[item observedObject] valueForKey:@"expanded"] boolValue] && ![outlineView isItemExpanded:item]) {
		[outlineView expandItem:item];
		[outlineView setValue:[NSNumber numberWithBool:YES] forKey:@"redrawWhenComplete"];
	}

	int type = [self typeForShadowItem:item];
	if (type > -1) {
		if ([_collectionImages count] > type) {
			[(ImageAndTextCell*)cell setImage:[_collectionImages objectAtIndex:type]];
		}            	
	}
}

- (void)outlineViewItemWillCollapse:(NSNotification *)notification
{
	// find out if the selection is contained by the item which is collapsing. If so, set the selection to that item
	MLCollection *collapsingCollection = [[[notification userInfo] valueForKey:@"NSObject"] observedObject];
	MLCollection *selectedCollection = [[groupTreeControl selectedObjects] objectAtIndex:0];
	MLCollection *parentCollection = [selectedCollection valueForKey:@"parent"];
	while (nil != parentCollection) {
		if ([parentCollection isEqual:collapsingCollection]) {
			[groupTreeControl setSelectionIndexPath:[groupTreeControl indexPathToObject:collapsingCollection]];
		}
		parentCollection = [parentCollection valueForKey:@"parent"];		
	}
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
//	NSLog(@"outlineViewItemDidCollapse: %@",[[[notification userInfo] valueForKey:@"NSObject"] observedObject]);
	[[[[notification userInfo] valueForKey:@"NSObject"] observedObject] setValue:[NSNumber numberWithBool:NO] forKey:@"expanded"];
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	[[[[notification userInfo] valueForKey:@"NSObject"] observedObject] setValue:[NSNumber numberWithBool:YES] forKey:@"expanded"];
}

//------------------------------------
#pragma mark NSOutlineView datasource methods -- see NSOutlineViewDataSource
//------------------------------------

- (BOOL) outlineView : (NSOutlineView *) outlineView 
					writeItems : (NSArray*) items 
				toPasteboard : (NSPasteboard*) pboard {

	draggedNode = [ items objectAtIndex:0 ];
	
	if ([self typeForShadowItem:draggedNode] > 0) {
		[ pboard declareTypes:dragType owner:self ];		
		// items is an array of _NSArrayControllerTreeNode see http://theocacao.com/document.page/130 for more info
		return YES;			
	}

	return NO;	
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index {
	
	int type = [self typeForShadowItem:item];
	NSData *gamesPasteboardData = [[info draggingPasteboard] dataForType:MLGamesPasteboardType];
	MLCollection *collection; 		
		
	// Library & smart collections don't accept drops
	if (type == 0 || type == 3) {
		return FALSE;
	}

	if (gamesPasteboardData && type == 2) {
		// add the game to an existing collection
		collection = [item observedObject];
		[collection addGamesWithNames:[NSUnarchiver unarchiveObjectWithData:gamesPasteboardData]];
		//NSLog(@"gamesPasteboardData: %@",[NSUnarchiver unarchiveObjectWithData:gamesPasteboardData]);
		return YES;
	}


	if (gamesPasteboardData) {
		// add the game to a new collection
		collection = [self newCollection];
		[collection addGamesWithNames:[NSUnarchiver unarchiveObjectWithData:gamesPasteboardData]];		
		return YES;
	}
	
	_NSArrayControllerTreeNode* parentNode = item;
	_NSArrayControllerTreeNode* siblingNode;
	_NSControllerTreeProxy* proxy = [ groupTreeControl arrangedObjects ];
		
	NSManagedObject* draggedGroup = [ draggedNode observedObject ];
			 
	BOOL draggingDown = NO;
	BOOL isRootLevelDrag = NO;
	
	// ----------------------
	// Setup comparison paths
	// -------------------------
	NSIndexPath* draggedPath = [ draggedNode indexPath ];
	NSIndexPath* siblingPath =  [ NSIndexPath indexPathWithIndex:  index  ];
	if ( parentNode == NULL ) {		
		isRootLevelDrag = YES;
	} else {
		// A non-root drag - the index value is relative to this parent's children
		siblingPath = [ [ parentNode indexPath ] indexPathByAddingIndex: index ];
	}
	
	// ----------------------
	// Compare paths - modify sibling path for down drags, exit for redundant drags
	// -----------------------------------------------------------------------------	
	switch ( [ draggedPath compare:siblingPath] ) {
		case NSOrderedAscending:  // reset path for down dragging
			if ( isRootLevelDrag ) {
				siblingPath = [ NSIndexPath indexPathWithIndex: index  - 1];							 
			} else {
			  siblingPath = [ [ parentNode indexPath ] indexPathByAddingIndex: index - 1 ]; 
			}
			draggingDown = YES;
			break;
		 
		case NSOrderedSame:
			return NO;
			break;				 
	}
		
	siblingNode = [ proxy nodeAtIndexPath:siblingPath ];	
	
//	NSLog(@"returning early");
//	return NO;  // TODO robustify
	
	
	// ------------------------------------------------------------	
	// SPECIAL CASE: Dragging to the bottom
	// ------------------------------------------------------------
	// - K								 - K							- C								 - C
	// - - U							 - - C     OR     - U								 - F
	// - - C     ====>     - - F				    - F								 - K
	// - - F               - U              - K								 - U
	// ------------------------------------------------------------ 
	if ( isRootLevelDrag  && siblingNode == NULL ) {		
		draggingDown = YES;
		siblingPath = [ NSIndexPath indexPathWithIndex: [ proxy count ] - 1 ];			
		siblingNode = [ proxy nodeAtIndexPath:siblingPath ] ;
	}
		
	// ------------------------------------------------------------	
	// Give the dragged item a position relative to it's new sibling
	// ------------------------------------------------------------	
	 NSManagedObject* sibling = [ siblingNode observedObject ];	 
	 NSNumber* bystanderPosition = [ sibling valueForKey:@"sequence"];
	 int newPos =   ( draggingDown ? [ bystanderPosition intValue ]  + 1 : [ bystanderPosition intValue ]  - 1 );
	 [draggedGroup setValue:[ NSNumber numberWithInt:newPos ] forKey:@"sequence"];	

	// ----------------------------------------------------------------------------------------------
	// Set the new parent for the dragged item, resort the position attributes and refresh the tree
	// ----------------------------------------------------------------------------------------------	 
	[ draggedGroup setValue:[ parentNode observedObject ] forKey:@"parent" ];
	[ self resortGroups:[draggedGroup managedObjectContext] forParent:[ parentNode observedObject ] ];			
	[ groupTreeControl rearrangeObjects ];  
	return YES;				
}






- (NSArray* ) getSubGroups:(NSManagedObjectContext*)objectContext forParent:(NSManagedObject*)parent {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"collection" inManagedObjectContext:objectContext];
	
	[request setEntity:entity];
	NSSortDescriptor* aSortDesc = [[NSSortDescriptor alloc] initWithKey:@"sequence" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject: aSortDesc] ];
	[aSortDesc release];
	
	NSPredicate* validationPredicate = [NSPredicate predicateWithFormat:@"parent == %@", parent ];
	
	[ request setPredicate:validationPredicate ];
	
	NSError *error = nil;  // TODO - check the error bozo
	return [objectContext executeFetchRequest:request error:&error];	
}




- (void) resortGroups:(NSManagedObjectContext*)objectContext forParent:(NSManagedObject*)parent {
	
	NSArray *array = [ self getSubGroups:objectContext forParent:parent ];
	
	// Reset the indexes...
	NSEnumerator *enumerator = [array objectEnumerator];
	NSManagedObject* anObject;
	int index = 0;
	while (anObject = [enumerator nextObject]) {
		// Multiply index by 10 to make dragging code easier to implement ;) ....
    [anObject setValue:[ NSNumber numberWithInt:(index * MLTreeInterval ) ] forKey:@"sequence"];	  
		index++;
	}	
	
	
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index {
	
	int type = [self typeForShadowItem:item];	
	NSData *gamePasteboardData = [[info draggingPasteboard] dataForType:MLGamesPasteboardType];
	_NSArrayControllerTreeNode* newParent = item;			
		
	// the library collection & smart collections don't accept drops
	if (type == 0 || type == 3) {
		return NSDragOperationNone;
	}	
	
	// games can only be dropped on collections
	if (gamePasteboardData && type == 1) {
		return NSDragOperationNone;
	}

	// collections only aceept dropped games
	if (!gamePasteboardData && type == 2) {
		return NSDragOperationNone;
	}
	
	// don't accept drops above the library collection item
	if (item == _libraryCollection && index == 0) {
		return NSDragOperationNone;
	}	
	
	if ( newParent == NULL ) {	
		// games dragged to the root indicate a new collection
		if (gamePasteboardData) {
			return NSDragOperationCopy;
		}
		// folder & collecion drags to the root are always acceptable
		return  NSDragOperationGeneric;	
	}

	// games dragged to collections are 'copied'
	if (gamePasteboardData) {
		return NSDragOperationCopy;
	}

	
		// Verify that we are not dragging a parent to one of it's ancestors
		// causes a parent loop where a group of nodes point to each other and disappear
		// from the control	
	 NSManagedObject* dragged = [ draggedNode observedObject ];	 	
	 NSManagedObject* newP = [ newParent observedObject ];

	 if ( [ self category:dragged isSubCategoryOf:newP ] ) {
		 return NO;
	 }		
	 
	return NSDragOperationGeneric;
}

- (BOOL) category:(NSManagedObject* )cat isSubCategoryOf:(NSManagedObject* ) possibleSub {
	
	 // Depends on your interpretation of subCategory ....
	if ( cat == possibleSub ) {	return YES; }
		
	NSManagedObject* possSubParent = [possibleSub valueForKey:@"parent"];	
	
	if ( possSubParent == NULL ) {	return NO; }
	
	while ( possSubParent != NULL ) {		
		if ( possSubParent == cat ) { return YES;	}
		
		// move up the tree
		possSubParent = [possSubParent valueForKey:@"parent"];			
	}	
	
	return NO;
}




// This method gets called by the framework but the values from bindings are used instead
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {	
	return NULL;
}

/* 
The following are implemented as stubs because they are required when 
 implementing an NSOutlineViewDataSource. Because we use bindings on the
 table column these methods are never called. The NSLog statements have been
 included to prove that these methods are not called.
 */
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {

	//NSLog(@"numberOfChildrenOfItem");
	return 1;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {

	//NSLog(@"isItemExpandable");
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {
	//NSLog(@"child of Item");
	return NULL;
}



@end
