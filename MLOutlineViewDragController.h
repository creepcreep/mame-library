//
//  MLOutlineViewDragController.h
//  MAME Library
//
//  Created by Johnnie Walker on 16/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Kudos to Matt Holiday and his Drag and Drop Outline Edit example
//http://homepage.mac.com/matthol2/cocoa/page2/files/DragAndDropOutlineEdit.zip

@interface _NSControllerTreeProxy : NSObject 
{
	// opaque
}
//
// Number of objects at the root level.
//
- (unsigned int)count;

- (id)nodeAtIndexPath:(id)fp8;
- (id)objectAtIndexPath:(id)fp8;
@end

@interface _NSArrayControllerTreeNode : NSObject
{
	// opaque
}
- (unsigned int)count;
- (id)observedObject;
- (id)parentNode;
- (id)nodeAtIndexPath:(id)fp8;
- (id)subnodeAtIndex:(unsigned int)fp8;
- (BOOL)isLeaf;
- (id)indexPath;
- (id)objectAtIndexPath:(id)fp8;
@end

// some more detailed reverse engineering is available here
// http://www.blueboxmoon.com/wiki/?page=Binding%20Tree

@class MLCollection;
@interface MLOutlineViewDragController : NSObject {
	IBOutlet NSArrayController *collectionsArrayController;
	IBOutlet NSTreeController *groupTreeControl;
	IBOutlet NSOutlineView *treeTable;
		
	NSArray *_collectionImages;
		
	NSArray* dragType;
	
	MLCollection *_libraryCollection;
	
	NSArray *_selectedCollectionsIndexPaths;		
				
	_NSArrayControllerTreeNode* draggedNode;
}
- (void) resortGroups:(NSManagedObjectContext*)objectContext forParent:(NSManagedObject*)parent;
- (NSArray* ) getSubGroups:(NSManagedObjectContext*)objectContext forParent:(NSManagedObject*)parent;
- (BOOL) category:(NSManagedObject* )cat isSubCategoryOf:(NSManagedObject* ) possibleSub;

- (int)typeForShadowItem:(id)item;

- (IBAction)addNewCollection:(id)sender;
- (MLCollection *)newCollection;
- (IBAction)addNewSmartCollection:(id)sender;
- (IBAction)addNewFolder:(id)sender;

- (BOOL)canRemove;
- (IBAction)delete:(id)sender;
@end


