//
//  ImageAndTextCell.h
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ImageAndTextCell : NSTextFieldCell {
@private
    NSImage	*_image;
	NSFont *_font;
	NSFont *_boldFont;
	NSMutableDictionary *_attrs;
}

- (void)setImage:(NSImage *)anImage;
- (NSImage *)image;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;
- (NSString*)truncateString:(NSString *)string forWidth:(double) inWidth andAttributes:(NSDictionary*)inAttributes;
@end