//
//  MLCollection.h
//  MAME Library
//
//  Created by Johnnie Walker on 16/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MLCollection : NSManagedObject {

}
- (NSDictionary *)titleDictionary;
- (NSPredicate *)predicate;
- (NSPredicate *)gamesPredicate;
- (void)addGamesWithNames:(NSArray *)names;
- (void)removeGames:(NSArray *)games;
- (NSPredicate *)predicateForGamesInArray:(NSArray *)games;
- (NSDictionary *)dictionaryRepresentation;
- (void)applyUserCollectionInfo:(NSDictionary *)userCollectionInfo;
@end
