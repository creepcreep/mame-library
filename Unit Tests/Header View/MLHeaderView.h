//
//  MLHeaderView.h
//  Header View
//
//  Created by Johnnie Walker on 04/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MLHeaderView : NSView {
	NSString *_value;
	NSNumber *_showClones;
	NSString *_orderByKey;
	NSNumber *_ascending;	
	NSDictionary *_attributes;
	
	NSRect _orderByKeyRect;
	NSRect _orderByRect;	
	
	BOOL _highlightOrderByKey;
	BOOL _highlightAscending;	

	int _orderByKeyTrackingRect;
	int _ascendingTrackingRect;	
}
- (NSBezierPath *)cartouchePathForRect:(NSRect)rect;
@end
