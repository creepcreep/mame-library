//
//  MLHeaderViewButtonCell.m
//  MAME Library
//
//  Created by Johnnie Walker on 23/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLHeaderViewButtonCell.h"


@implementation MLHeaderViewButtonCell

- (BOOL)isOpaque 
{ 
    return YES; 
} 

- (id)copyWithZone:(NSZone *)zone
{
    id newCopy = [super copyWithZone:zone];
    
	[_gradientImg retain];
    [_gradientImgFlipped retain];
	[_bgColor retain];
	
    return newCopy;
}

- (void)commonInit 
{ 
     //Load images 
	_gradientImg = [[NSImage imageNamed:@"header_gradient"] retain];      
	_gradientImgFlipped = [[NSImage imageNamed:@"header_gradient_flipped"] retain];      

    [_gradientImg lockFocus];
    // _bgColor = [NSReadPixel(NSMakePoint(0, 0)) retain];
	_bgColor = [[NSColor colorWithCalibratedRed:0.38f green:0.38f blue:0.38f alpha:1.0f] retain];		
    [_gradientImg unlockFocus];
	[self setHighlightsBy:NSNoCellMask];
} 

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) { 
        [self commonInit]; 
    } 
 
    return self; 
}

- (id)initTextCell:(NSString *)str 
{ 
    if ((self = [super initTextCell:str])) { 
        [self commonInit]; 
    } 
 
    return self;     
} 
- (id)initImageCell:(NSImage *)image 
{ 
    if ((self = [super initImageCell:image])) { 
        [self commonInit]; 
    } 
     
    return self;     
} 

- (void)dealloc 
{ 
    [_gradientImgFlipped release];    
    [_gradientImg release];  
	[_bgColor release];  
     
    [super dealloc]; 
} 

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[self drawInteriorWithFrame:cellFrame inView:controlView]; 
}

- (void)setHighlighted:(BOOL)flag
{
	return;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {

	NSLog(@"drawInteriorWithFrame:");
	
	NSImage *bgImg = _gradientImg;
	if ([self state] == NSOnState || [self isHighlighted]) {
		bgImg = _gradientImgFlipped;
	}

    // Drawing code here.
	[_bgColor set];
    NSRectFill(cellFrame);	

//	[bgImg drawInRect:NSMakeRect(cellFrame.origin.x, cellFrame.origin.y+1.0, cellFrame.size.width, cellFrame.size.width)
//				  fromRect:NSMakeRect(0, 0, 
//									  [bgImg size].width, 
//									  [bgImg size].height) 
//				 operation:NSCompositeSourceOver 
//				  fraction:1.0];					  

	NSImage *img = [self image];
	[img setFlipped:YES];	
//	[img drawInRect:cellFrame
//				  fromRect:NSMakeRect(0, 0, 
//									  [img size].width, 
//									  [img size].height) 
//				 operation:NSCompositeSourceOver 
//				  fraction:1.0];	

}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[self drawWithFrame:cellFrame inView:controlView];
}

@end
