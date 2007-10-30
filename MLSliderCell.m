//
//  MLSliderCell.m
//  MAME Library
//
//  Created by Johnnie Walker on 18/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLSliderCell.h"


@implementation MLSliderCell

- (void) dealloc {
	
	[_knobImage release];
	[_knobImageOn release];	
	
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	[super initWithCoder:decoder];

	_knobImage = [[NSImage imageNamed:@"Knob_ImageZoomSlider-N"] retain];
	_knobImageOn = [[NSImage imageNamed:@"Knob_ImageZoomSlider-P"] retain];	
	_currentImage = _knobImage;

	return self;
}

- (void)drawKnob:(NSRect)knobRect
{	
	NSImage *img = _currentImage;

	[img drawInRect:NSMakeRect(knobRect.origin.x+((knobRect.size.width - [img size].width)/2),knobRect.origin.y+((knobRect.size.width - [img size].height)/2),[img size].width,[img size].height)  
		fromRect:NSMakeRect(0,0,[img size].width,[img size].height) 
		operation:NSCompositeSourceOver fraction:1.0];	
}

//- (void)setNextState
//{
//	NSLog(@"setNextState");
//	[super setNextState];
//	
//	if ([self state] == NSOnState) {
//		_currentImage = _knobImageOn;
//		[[self controlView] display];
//		return;
//	}
//	
//	_currentImage = _knobImage;	
//	[[self controlView] display];	
//}
//
//- (void)setState:(int)value {
//
//	[super setState:value];
//
//	NSLog(@"setState: %i",value);
//	
//	if (value == NSOnState) {
//		_currentImage = _knobImageOn;
//		[[self controlView] display];
//		return;
//	}
//	
//	_currentImage = _knobImage;	
//	[[self controlView] display];
//}

@end
