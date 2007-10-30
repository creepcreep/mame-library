//
//  MLTableHeaderImageCell.m
//  MAME Library
//
//  Created by Johnnie Walker on 24/07/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MLTableHeaderImageCell.h"


@implementation MLTableHeaderImageCell

- (id)initImageCell:(NSImage *)anImage
{
    if (self = [super initImageCell:anImage]) {
		_image = [anImage retain];
//        _metalBg = [[NSImage imageNamed:@"table_view_active.png"] retain];
        [_image setFlipped:YES];
        return self;
    }
    return nil;
}

- (void)dealloc
{
    [_image release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    id newCopy = [super copyWithZone:zone];
    
	[_image retain];	
	
    return newCopy;
}

- (void)drawWithFrame:(NSRect)inFrame inView:(NSView*)inView
{
//	NSLog(@"_image: %@",_image);
    [_image drawInRect:inFrame fromRect:NSMakeRect(0,0,[_image size].width,[_image size].height) operation:NSCompositeSourceOver fraction:1.0];
    
}

@end
