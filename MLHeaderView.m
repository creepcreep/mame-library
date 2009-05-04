//
//  MLHeaderView.m
//  MAME Library
//
//  Created by Johnnie Walker on 23/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLHeaderView.h"

static void *sortDescendingBindingContext = (void *)@"sortDescendingBinding";
static void *orderByKeyBindingContext = (void *)@"orderByKeyBinding";
static void *orderByKeyTitleBindingContext = (void *)@"orderByKeyBindingTitle";

@implementation MLHeaderView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_gradientImg = [[NSImage imageNamed:@"header_gradient"] retain];		
		
		[self setValue:@"All games" forKey:@"value"];
//		[self setValue:[NSNumber numberWithBool:YES] forKey:@"ascending"];
		[self setValue:@"Title" forKey:@"orderByKey"];		
		
		_attributes	= [[NSMutableDictionary dictionaryWithObject:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName] retain];
		
		_bgColor = [[NSColor colorWithCalibratedRed:0.38f green:0.38f blue:0.38f alpha:1.0f] retain];		
		// _bgColor = [[NSColor blueColor] retain];
    }
    return self;
}

+ (void)initialize {
	[self exposeBinding:@"sortDescending"];
}

- (void)bind:(NSString *)binding toObject:(id)observableObject withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{	
	if ([binding isEqualToString:@"sortDescending"]) {
		[observableObject addObserver:self forKeyPath:keyPath options:0 context:sortDescendingBindingContext];	
		observedObjectForSortDescending = [observableObject retain];
		observedKeyPathForSortDescending = [[keyPath copy] retain];
	} else if ([binding isEqualToString:@"orderByKey"]) {
		[observableObject addObserver:self forKeyPath:keyPath options:0 context:orderByKeyBindingContext];	
		observedObjectForOrderByKey = [observableObject retain];
		observedKeyPathForOrderByKey = [[keyPath copy] retain];
	} else if ([binding isEqualToString:@"orderByKeyTitle"]) {
		[observableObject addObserver:self forKeyPath:keyPath options:0 context:orderByKeyTitleBindingContext];	
		observedObjectForOrderByKeyTitle = [observableObject retain];
		observedKeyPathForOrderByKeyTitle = [[keyPath copy] retain];
	} 
	
	[super bind:binding toObject:observableObject withKeyPath:keyPath options:options];
}

- (void) dealloc {

	[observedObjectForOrderByKey release];
	[observedKeyPathForOrderByKey release];	

	[observedObjectForOrderByKeyTitle release];
	[observedKeyPathForOrderByKeyTitle release];	
	
	[observedKeyPathForSortDescending release];
	[observedObjectForSortDescending release];

	[_attributes release];
	[_gradientImg release];
	
	[_bgColor release];  
	
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == sortDescendingBindingContext) {
		[self setValue:[object valueForKeyPath:keyPath] forKeyPath:@"sortDescending"];
	} else if (context == orderByKeyBindingContext) {
		[self setValue:[object valueForKeyPath:keyPath] forKeyPath:@"orderByKey"];
	} else if (context == orderByKeyTitleBindingContext) {
		[self setValue:[object valueForKeyPath:keyPath] forKeyPath:@"orderByKeyTitle"];
	}
	[self setNeedsDisplay:YES];			
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	[_bgColor set];
    NSRectFill(rect);	
	
	[_gradientImg drawInRect:NSMakeRect(rect.origin.x, rect.origin.y+1.0f, rect.size.width, rect.size.height-1.0)
				  fromRect:NSMakeRect(0, 0, 
									  [_gradientImg size].width, 
									  [_gradientImg size].height) 
				 operation:NSCompositeSourceOver 
				  fraction:1.0];	
	
	NSString *preambleString;
	NSString *orderByString;
	NSString *punctuationString;
	NSString *orderString;
	
	orderString = @"ascending";
	if ([[self valueForKey:@"sortDescending"] boolValue]) {
		orderString = @"descending";
	}		
	
	preambleString = [NSString stringWithFormat:@"%@ by ",[self valueForKey:@"value"]];
	orderByString = [NSString stringWithFormat:@"%@",[[self valueForKey:@"orderByKeyTitle"] lowercaseString]];
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

	NSPoint drawingOrigin = NSMakePoint(rect.origin.x + ((rect.size.width - bounds.size.width)/2),rect.origin.y+2);
	preambleStringBounds.origin = drawingOrigin;
	bounds.origin = drawingOrigin;
	
	_orderByKeyRect = NSMakeRect(drawingOrigin.x + preambleStringBounds.size.width,drawingOrigin.y,orderByStringBounds.size.width,orderByStringBounds.size.height);
	_orderByRect = NSMakeRect(_orderByKeyRect.origin.x + _orderByKeyRect.size.width + punctuationStringBounds.size.width,drawingOrigin.y,orderStringBounds.size.width,orderStringBounds.size.height);	
	
	NSPoint punctuationPoint = NSMakePoint(_orderByKeyRect.origin.x + _orderByKeyRect.size.width,_orderByKeyRect.origin.y);
	punctuationStringBounds.origin = punctuationPoint;

	[self removeTrackingRect:_orderByKeyTrackingRect];
	[self removeTrackingRect:_ascendingTrackingRect];		

	_orderByKeyTrackingRect = [self addTrackingRect:_orderByKeyRect owner:self userData:nil assumeInside:_highlightOrderByKey];
	_ascendingTrackingRect = [self addTrackingRect:_orderByRect owner:self userData:nil assumeInside:_highlightAscending];	

	if (_highlightOrderByKey) {
		[[NSColor grayColor] set];
		
		NSBezierPath *highlightOrderByPath = [self cartouchePathForRect:_orderByKeyRect];
		[highlightOrderByPath fill];		
	}
	
	if (_highlightAscending) {
		[[NSColor grayColor] set];

		NSBezierPath *highlightAscendingPath = [self cartouchePathForRect:_orderByRect];
		[highlightAscendingPath fill];			
	}

	NSString *concatString = [NSString stringWithFormat:@"%@%@%@%@",preambleString,orderByString,punctuationString,orderString];
//	bounds.origin.y -= 0.5;
	[_attributes setValue:[NSColor colorWithCalibratedWhite:1.0 alpha:0.7] forKey:@"NSColor"];
	[concatString drawInRect:bounds withAttributes:_attributes];
	bounds.origin.y += 0.5;	
	[_attributes setValue:[NSColor blackColor] forKey:@"NSColor"];
	[concatString drawInRect:bounds withAttributes:_attributes];	
	
//	[preambleString drawInRect:preambleStringBounds withAttributes:_attributes];
//	[orderByString drawInRect:_orderByKeyRect withAttributes:_attributes];
//	[punctuationString drawInRect:punctuationStringBounds withAttributes:_attributes];
//	[orderString drawInRect:_orderByRect withAttributes:_attributes];			
	
}

- (NSBezierPath *)cartouchePathForRect:(NSRect)rect
{
	NSRect insertRect = NSInsetRect(rect,1.25,0.25);

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
		[self setValue:[NSNumber numberWithBool:![[self valueForKey:@"sortDescending"] boolValue]] forKey:@"sortDescending"];
		if (nil != observedObjectForSortDescending) {
			[observedObjectForSortDescending setValue:[self valueForKey:@"sortDescending"] forKeyPath:observedKeyPathForSortDescending];
		}
	}
	[self setNeedsDisplay:YES];
}

@end
