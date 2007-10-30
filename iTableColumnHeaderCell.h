//
//  iTableColumnHeaderCell.h
//  iTableColumnHeader
//
//  Created by Matt Gemmell on Thu Feb 05 2004.
//  <http://iratescotsman.com/>
//

#import <Cocoa/Cocoa.h>


@interface iTableColumnHeaderCell : NSTableHeaderCell {
    NSImage *_metalBacking;
	NSColor *_bgColor;	
    NSMutableDictionary *_attributes;
	NSRect _drawingRect;	
	NSArray *_sortDescriptors;
}

@end
