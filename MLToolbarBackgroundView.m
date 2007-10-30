//
//  MLToolbarBackgroundView.m
//  MAME Library
//
//  Created by Johnnie Walker on 19/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLToolbarBackgroundView.h"


@implementation MLToolbarBackgroundView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_bgColor = [[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.88 alpha:1.0] retain];
    }
    return self;
}

- (void) dealloc {
	[_bgColor release];
	[super dealloc];
}


- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	[_bgColor set];
    NSRectFill(rect);
}

@end
