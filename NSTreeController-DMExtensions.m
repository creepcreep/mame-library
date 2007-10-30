//  NSTreeController-DMExtensions.m
//  Library
//
//  Created by William Shipley on 3/10/06.
//  Copyright 2006 Delicious Monster Software, LLC. Some rights reserved,
//    see Creative Commons license on wilshipley.co

#import "NSTreeController-DMExtensions.h"

@implementation NSTreeController (DMExtensions)

- (void)setSelectedObjects:(NSArray *)newSelectedObjects;
{
	[self prepareContent];
	[self fetch:self];
	NSMutableArray *indexPaths = [NSMutableArray array];
	unsigned int selectedObjectIndex;
	for (selectedObjectIndex = 0; selectedObjectIndex < [newSelectedObjects count]; selectedObjectIndex++) {
		id selectedObject = [newSelectedObjects objectAtIndex:selectedObjectIndex];
		NSIndexPath *indexPath = [self indexPathToObject:selectedObject];
		NSLog(@"indexPath: %@",indexPath);
		if (indexPath) {
			[indexPaths addObject:indexPath];
		}
	}

	[self setSelectionIndexPaths:indexPaths];
}

- (NSIndexPath *)indexPathToObject:(id)object;
{
	NSMutableArray *children = [NSMutableArray arrayWithArray:[self content]];
	[children sortUsingDescriptors:[self sortDescriptors]];

	return [self _indexPathFromIndexPath:nil inChildren:children childCount:[children count] toObject:object];
}

@end


@implementation NSTreeController (DMExtensions_Private)

- (NSIndexPath *)_indexPathFromIndexPath:(NSIndexPath *)baseIndexPath inChildren:(NSArray *)children
childCount:(unsigned int)childCount toObject:(id)object;
{
	unsigned int childIndex;
	for (childIndex = 0; childIndex < childCount; childIndex++) {
		id childObject = [children objectAtIndex:childIndex];

//		NSLog(@"childObject: %@",[childObject valueForKey:@"title"]);

		NSMutableSet *childsChildren = nil;
		unsigned int childsChildrenCount = 0;
		NSString *leafKeyPath = [self leafKeyPath];
		
		if (!leafKeyPath || [[childObject valueForKey:leafKeyPath] boolValue] == NO) {
			NSString *countKeyPath = [self countKeyPath];
			if (countKeyPath) {
				childsChildrenCount = [[childObject valueForKey:leafKeyPath] unsignedIntValue];
			}
			if (!countKeyPath || childsChildrenCount != 0) {
				NSString *childrenKeyPath = [self childrenKeyPath];
				childsChildren = [childObject mutableSetValueForKey:childrenKeyPath];
				if (!countKeyPath) {
					childsChildrenCount = [childsChildren count];
				}
			}
		}

		BOOL objectFound = [object isEqual:childObject];
		
//		NSLog(@"objectFound: %i (%i/%i)",objectFound,YES,NO);
		
		if (!objectFound && childsChildrenCount == 0)
		continue;

		NSIndexPath *indexPath = (baseIndexPath == nil) ? [NSIndexPath indexPathWithIndex:childIndex] : [baseIndexPath indexPathByAddingIndex:childIndex];


		if (objectFound) {
			return indexPath;
		}
		
		//change NSSet to NSArray and sort
		NSMutableArray *childsChildrenAsArray = [NSMutableArray arrayWithArray:[childsChildren allObjects]];
		[childsChildrenAsArray sortUsingDescriptors:[self sortDescriptors]];

		NSIndexPath *childIndexPath = [self _indexPathFromIndexPath:indexPath inChildren:childsChildrenAsArray
		childCount:childsChildrenCount toObject:object];
		if (childIndexPath) {
			return childIndexPath;
		}
	}

	return nil;
}

@end