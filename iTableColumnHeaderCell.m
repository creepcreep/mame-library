//
//  iTableColumnHeaderCell.m
//  iTableColumnHeader
//
//  Created by Matt Gemmell on Thu Feb 05 2004.
//  <http://iratescotsman.com/>
//

#import "iTableColumnHeaderCell.h"


@implementation iTableColumnHeaderCell


- (id)initTextCell:(NSString *)text
{
    if (self = [super initTextCell:text]) {
        _metalBacking = [[NSImage imageNamed:@"header_gradient_flipped.png"] retain];

		[_metalBacking lockFocus];
		_bgColor = [NSReadPixel(NSMakePoint(0, 0)) retain];
		[_metalBacking unlockFocus];

		[self setBackgroundColor:[NSColor colorWithPatternImage:_metalBacking]];
		[self setDrawsBackground:YES];
		[self setBordered:NO];
		[self setBezeled:NO];
		[self setFocusRingType:NSFocusRingTypeNone];

        if (text == nil || [text isEqualToString:@""]) {
            [self setTitle:@"Title"];
        }
//        [metalBg setFlipped:YES];
        _attributes = [[NSMutableDictionary dictionaryWithDictionary:
                                        [[self attributedStringValue] 
                                                    attributesAtIndex:0 
                                                    effectiveRange:NULL]] 
                                                        mutableCopy];
        return self;
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    id newCopy = [super copyWithZone:zone];
    [_bgColor retain];
    [_metalBacking retain];
    [_attributes retain];
    return newCopy;
}

- (void)dealloc
{
	[_bgColor release];
    [_metalBacking release];
    [_attributes release];
    [super dealloc];
}

- (void)drawWithFrame:(NSRect)frame inView:(NSView*)inView {

	NSRect tempSrc = NSZeroRect;
//	NSRect tempDst = frame;

	// Draw _metalBacking along width of frame.
	tempSrc.origin.y = 0.0;
	tempSrc.size.height = [_metalBacking size].height + 2.0;

//	tempDst.origin.y -= 2.0;
//	tempDst.size.height = frame.size.height + 2.0;

	[_metalBacking drawInRect:frame fromRect:tempSrc operation:NSCompositeSourceOver fraction:1.0];

	// Draw white text centered.
	float offset = 0.5;
	[_attributes setValue:[NSColor colorWithCalibratedWhite:1.0 alpha:0.7] forKey:@"NSColor"];

	NSRect centeredRect = frame;
	centeredRect.size = [[self stringValue] sizeWithAttributes:_attributes];
	centeredRect.origin.x += ((frame.size.width - centeredRect.size.width) / 2.0) - offset;
	centeredRect.origin.y = ((frame.size.height - centeredRect.size.height) / 2.0) + offset;
	[[self stringValue] drawInRect:centeredRect withAttributes:_attributes];

	[_attributes setValue:[NSColor blackColor] forKey:@"NSColor"];
	centeredRect.origin.y -= offset;
	[[self stringValue] drawInRect:centeredRect withAttributes:_attributes];

	// Draw the column divider.
	[_bgColor set];

	// first find the column we're drawing the header of - why this isn't a method argument is beyond me
	NSTableView *tv = [(NSTableHeaderView *)inView tableView];
	int colIndex = [tv columnAtPoint:NSMakePoint(frame.origin.x + (frame.size.width/2),frame.origin.y + (frame.size.height/2))];

	if (colIndex < [[tv tableColumns] count]) {
		NSTableColumn *col = [[tv tableColumns] objectAtIndex:colIndex];

		NSRect rect = [tv rectOfColumn:colIndex];
		NSRect dividerRect = NSMakeRect(rect.origin.x + rect.size.width - 1, rect.origin.y, 1,rect.size.height);

		NSRectFill(dividerRect);

		NSArray *descriptors = [self valueForKey:@"sortDescriptors"];
		NSSortDescriptor *descriptor;
		NSImage *indicator;

		if ([descriptors count] > 0) {
			descriptor = [descriptors objectAtIndex:0];
			if ([[descriptor key] isEqual:[col identifier]]) {
				if (![descriptor ascending]) {
					indicator = [NSImage imageNamed:@"NSAscendingSortIndicator"];
				} else {
					indicator = [NSImage imageNamed:@"NSDescendingSortIndicator"];
				}
				[indicator drawInRect:[self sortIndicatorRectForBounds:frame] fromRect:NSMakeRect(0,0,[indicator size].width,[indicator size].height) operation:NSCompositeSourceOver fraction:1.0];
			}
		}
	}
	
}

@end
