//
//  MAMEXMLParser.h
//  Data Model
//
//  Created by Johnnie Walker on 14/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MAMEXMLParser : NSObject {

	IBOutlet NSWindow *_progressWindow;

	NSString *_status;
	NSString *_statusPrefix;	
	NSNumber *_importing;
	NSNumber *_progress;
	NSXMLParser *_parser;
	
	NSManagedObject *_currentGame;
	NSManagedObject *_currentEntity;	
	NSString *_foundCharacters;
	
	NSManagedObjectContext *_context;
	NSManagedObjectModel *_model;	
	
	int _gameCount;
	int _totalGames;	
	int _gamesSinceSave;		
}
-(void)parseXMLFile:(NSString *)file;
- (void)createEntityWithName:(NSString *)elementName addingAttributes:(NSArray *)attributes fromAttributeDictionary:(NSDictionary *)attributeDict;
- (void)setAttrributesFromDictionary:(NSDictionary *)attributeDict withKeys:(NSArray *)attributeKeys onEntity:(NSManagedObject *)entity;
- (void)removeNestedEntitiesWithRelationshipNames:(NSArray *)names fromEntity:(NSManagedObject *)entity;
-(void)doParse:(NSString *)file;
- (IBAction) saveAction:(id)sender;
@end
