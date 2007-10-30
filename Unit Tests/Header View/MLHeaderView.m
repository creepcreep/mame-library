//
//  MLHeaderView.m
//  Header View
//
//  Created by Johnnie Walker on 04/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLHeaderView.h"


@implementation MLHeaderView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self setValue:@"All games" forKey:@"value"];
		[self setValue:[NSNumber numberWithBool:NO] forKey:@"showClones"];
		[self setValue:[NSNumber numberWithBool:YES] forKey:@"ascending"];
		[self setValue:@"Title" forKey:@"orderByKey"];						
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
//	NSLog(@"drawRect:");

    // Drawing code here.
	
	NSString *preambleString;
	NSString *orderByString;
	NSString *punctuationString;
	NSString *orderString;
	
	orderString = @"ascending";
	if (![[self valueForKey:@"ascending"] boolValue]) {
		orderString = @"descending";
	}
	
	NSString *filter = @"";
	if (![[self valueForKey:@"showClones"] boolValue]) {
		filter = @"(excluding clones) ";
	}	
	
	
	preambleString = [NSString stringWithFormat:@"%@ %@by ",[self valueForKey:@"value"],filter];
	orderByString = [NSString stringWithFormat:@"%@",[[self valueForKey:@"orderByKey"] lowercaseString]];
	punctuationString = @", ";

	NSRect preambleStringBounds = [preambleString boundingRectWithSize:rect.size options:0 attributes:_attributes];
	NSRect orderByStringBounds = [orderByString boundingRectWithSize:rect.size options:0 attributes:_attributes];
	NSRect punctuationStringBounds = [punctuationString boundingRectWithSize:rect.size options:0 attributes:_attributes];
	NSRect orderStringBounds = [orderString boundingRectWithSize:rect.size options:0 attributes:_attributes];			
	
	NSRect bounds = NSMakeRect(preambleStringBounds.origin.x,
						preambleStringBounds.origin.y,
						preambleStringBounds.size.width + orderByStringBounds.size.width + punctuationStringBounds.size.width + orderStringBounds.size.width,
						preambleStringBounds.size.height
						);

	NSPoint drawingOrigin = NSMakePoint(rect.origin.x + ((rect.size.width - bounds.size.width)/2),rect.origin.y);
	
	_orderByKeyRect = NSMakeRect(drawingOrigin.x + preambleStringBounds.size.width,drawingOrigin.y,orderByStringBounds.size.width,orderByStringBounds.size.height);
	_orderByRect = NSMakeRect(_orderByKeyRect.origin.x + _orderByKeyRect.size.width + punctuationStringBounds.size.width,drawingOrigin.y,orderStringBounds.size.width,orderStringBounds.size.height);	
	
	NSPoint punctuationPoint = NSMakePoint(_orderByKeyRect.origin.x + _orderByKeyRect.size.width,_orderByKeyRect.origin.y);

	[self removeTrackingRect:_orderByKeyTrackingRect];
	[self removeTrackingRect:_ascendingTrackingRect];		

	_orderByKeyTrackingRect = [self addTrackingRect:_orderByKeyRect owner:self userData:nil assumeInside:_highlightOrderByKey];
	_ascendingTrackingRect = [self addTrackingRect:_orderByRect owner:self userData:nil assumeInside:_highlightAscending];	

	if (_highlightOrderByKey) {
		[[NSColor lightGrayColor] set];
		
		NSBezierPath *highlightOrderByPath = [self cartouchePathForRect:_orderByKeyRect];
		[highlightOrderByPath fill];		
	}
	
	if (_highlightAscending) {
		[[NSColor lightGrayColor] set];

		NSBezierPath *highlightAscendingPath = [self cartouchePathForRect:_orderByRect];
		[highlightAscendingPath fill];			
	}
	
	[preambleString drawAtPoint:drawingOrigin withAttributes:_attributes];
	[orderByString drawAtPoint:_orderByKeyRect.origin withAttributes:_attributes];
	[punctuationString drawAtPoint:punctuationPoint withAttributes:_attributes];
	[orderString drawAtPoint:_orderByRect.origin withAttributes:_attributes];			
	
}

- (NSBezierPath *)cartouchePathForRect:(NSRect)rect
{
	NSRect insertRect = NSInsetRect(rect,1.5,0.5);

	NSBezierPath *path = [NSBezierPath bezierPathWithRect:insertRect];
	
	[path appendBezierPathWithOvalInRect:NSMakeRect(insertRect.origin.x-(insertRect.size.height/4),insertRect.origin.y,insertRect.size.height/2,insertRect.size.height)];
	[path appendBezierPathWithOvalInRect:NSMakeRect(insertRect.origin.x+insertRect.size.width-(insertRect.size.height/4),insertRect.origin.y,insertRect.size.height/2,insertRect.size.height)];
	
	return path;
}

- (void)mouseEntered:(NSEvent *)theEvent {
//	NSLog(@"mouseEntered:");
	if ([theEvent trackingNumber] == _orderByKeyTrackingRect) {
		_highlightOrderByKey = YES;
	} else if ([theEvent trackingNumber] == _ascendingTrackingRect) {
		_highlightAscending = YES;
	}
	[self setNeedsDisplay:YES];
}
	
- (void)mouseExited:(NSEvent *)theEvent {
//	NSLog(@"mouseExited:");
	if ([theEvent trackingNumber] == _orderByKeyTrackingRect) {
		_highlightOrderByKey = NO;
	} else if ([theEvent trackingNumber] == _ascendingTrackingRect) {
		_highlightAscending = NO;
	}
	[self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent
{
//	NSLog(@"theEvent: %@",theEvent);

	if (_highlightOrderByKey) {
		// open the menu
		[NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:self];
		_highlightOrderByKey = NO;
	} else if (_highlightAscending) {
		// toggle the ascending status
		[self setValue:[NSNumber numberWithBool:![[self valueForKey:@"ascending"] boolValue]] forKey:@"ascending"];
	}
	[self setNeedsDisplay:YES];
}

@end
