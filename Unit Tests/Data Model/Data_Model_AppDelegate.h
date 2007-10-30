//
//  Data_Model_AppDelegate.h
//  Data Model
//
//  Created by Johnnie Walker on 03/07/2007.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MAMEXMLParser;
@interface Data_Model_AppDelegate : NSObject 
{
    IBOutlet NSWindow *window;
    IBOutlet NSTextView *textView;	
    IBOutlet MAMEXMLParser *parser;
		
	NSString *status;
	
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	
//	NSNumberFormatter *numberFormatter;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)saveAction:sender;
- (IBAction)openXMLFile:sender;
//- (id)valueForData:(id)data usingType:(id)type;
//- (NSManagedObject *)entityFromNode:(NSXMLElement *)node withStructure:(NSDictionary *)structure;
//- (IBAction)parseXML:sender;

@end
