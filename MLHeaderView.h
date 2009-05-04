//
//  MLHeaderView.h
//  MAME Library
//
//  Created by Johnnie Walker on 23/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MLHeaderView : NSView {
	NSImage *_gradientImg;
	NSColor *_bgColor;
	NSString *_value;
	NSString *_orderByKey;
	NSString *_orderByKeyTitle;	
	NSNumber *_sortDescending;	
	NSMutableDictionary *_attributes;
	
	id observedObjectForSortDescending;
	NSString *observedKeyPathForSortDescending;	

	id observedObjectForOrderByKey;
	NSString *observedKeyPathForOrderByKey;	

	id observedObjectForOrderByKeyTitle;
	NSString *observedKeyPathForOrderByKeyTitle;
	
	NSRect _orderByKeyRect;
	NSRect _orderByRect;	
	
	BOOL _highlightOrderByKey;
	BOOL _highlightAscending;	

	int _orderByKeyTrackingRect;
	int _ascendingTrackingRect;	
}
- (NSBezierPath *)cartouchePathForRect:(NSRect)rect;
@end

