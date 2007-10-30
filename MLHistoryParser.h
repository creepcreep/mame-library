//
//  MLHistoryParser.h
//  MAME Library
//
//  Created by Johnnie Walker on 04/09/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MLHistoryParser : NSObject {
	NSManagedObjectContext *_context;
	NSManagedObjectModel *_model;	
}
-(void)parseHistoryDataAtPath:(NSString *)path;
- (IBAction) saveAction:(id)sender;
@end
