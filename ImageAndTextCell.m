/*
	ImageAndTextCell.m
	Copyright (c) 2001-2002, Apple Computer, Inc., all rights reserved.
	Author: Chuck Pisula

	Milestones:
	Initially created 3/1/01

        Subclass of NSTextFieldCell which can display text and an image simultaneously.
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under AppleÕs copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "ImageAndTextCell.h"
#import "CTGradient.h"

@implementation ImageAndTextCell

- (id) init {
	self = [super init];
	if (self != nil) {		
		_font = [[NSFont fontWithName:@"Lucida Grande" size:11] retain];
		_boldFont = [[[NSFontManager sharedFontManager] convertFont:_font toHaveTrait:NSUnboldFontMask] retain];
		_attrs = [[NSMutableDictionary dictionaryWithDictionary:[[self attributedStringValue] attributesAtIndex:0 effectiveRange:NULL]] retain];
		[_attrs setObject:_font forKey:NSFontAttributeName];
		[self setWraps:NO];  // Important so the text doesn't wrap during editing.
		[self setFont:_font];
	}
	return self;
}

- (void)dealloc {
    [_attrs release];
    [_image release];
    [_font release];	
    [_boldFont release];		
    [super dealloc];
}

- copyWithZone:(NSZone *)zone {
    ImageAndTextCell *cell = (ImageAndTextCell *)[super copyWithZone:zone];
    cell->_image = [_image retain];
    cell->_attrs = [_attrs retain];	
    cell->_font = [_font retain];	
    cell->_boldFont = [_boldFont retain];			
//    [cell setImage:[self image]];
    return cell;
}

- (void)setImage:(NSImage *)anImage {
    if (anImage != _image) {
        [_image release];
        _image = [anImage retain];
    }
}

- (NSImage *)image {
    return _image;
}

- (NSRect)imageFrameForCellFrame:(NSRect)cellFrame {
    if (_image != nil) {
        NSRect imageFrame;
        imageFrame.size = [_image size];
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += 3;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    }
    else
        return NSZeroRect;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [_image size].width, NSMinXEdge);

	textFrame = NSMakeRect(textFrame.origin.x+5,textFrame.origin.y+(textFrame.size.height-16)/2,textFrame.size.width-5,16);	
    [super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [_image size].width, NSMinXEdge);

	textFrame = NSMakeRect(textFrame.origin.x+5,textFrame.origin.y+(textFrame.size.height-16)/2,textFrame.size.width-5,16);	
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
			
	if ([self isHighlighted]) {
		NSRect gradientFrame = cellFrame;
		gradientFrame.origin.x = [controlView frame].origin.x;
		gradientFrame.size.width = [controlView frame].size.width;		
	
			/* Determine whether we should draw a blue or grey gradient. */
			/* We will automatically redraw when our parent view loses/gains focus, or when our parent window loses/gains main/key status. */
		if (([[controlView window] firstResponder] == controlView) && 
				[[controlView window] isMainWindow] &&
				[[controlView window] isKeyWindow]) {
			[[CTGradient sourceListSelectedGradient] fillRect:gradientFrame angle:270];

		} else {
			[[CTGradient sourceListUnselectedGradient] fillRect:gradientFrame angle:270];
		}
		
		// If this line is selected, we want a bold white font.
		[_attrs setValue:_boldFont forKey:@"NSFont"];
		[_attrs setValue:[NSColor whiteColor] forKey:@"NSColor"];
	} else {
		[_attrs setValue:_font forKey:@"NSFont"];
		[_attrs setValue:[NSColor blackColor] forKey:@"NSColor"];
	}
	
    if (_image != nil) {
        NSSize	imageSize;
        NSRect	imageFrame;

        imageSize = [_image size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, 3 + imageSize.width, NSMinXEdge);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.origin.x += 3;
        imageFrame.size = imageSize;

        if ([controlView isFlipped])
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        else
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);

        [_image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
	
	NSRect textFrame = NSMakeRect(cellFrame.origin.x+5,cellFrame.origin.y+(cellFrame.size.height-16)/2,cellFrame.size.width-5,16);	
//    [super drawWithFrame:textFrame inView:controlView];

//	NSLog(@"[self stringValue]: %@, attrs: %@",[self stringValue],_attrs);

	NSString *displayString = [self truncateString:[self stringValue]
										  forWidth:textFrame.size.width
									 andAttributes:_attrs];
	
	[displayString drawAtPoint:textFrame.origin withAttributes:_attrs];


}

	// Not from Matt's class. Added this later. -DB
- (NSString*)truncateString:(NSString *)string forWidth:(double) inWidth andAttributes:(NSDictionary*)inAttributes
{
    unichar  ellipsesCharacter = 0x2026;
    NSString* ellipsisString = [NSString stringWithCharacters:&ellipsesCharacter length:1];
	
    NSString* truncatedString = [NSString stringWithString:string];
    int truncatedStringLength = [truncatedString length];
	
    if ((truncatedStringLength > 2) && ([truncatedString sizeWithAttributes:inAttributes].width > inWidth))
    {
        double targetWidth = inWidth - [ellipsisString sizeWithAttributes:inAttributes].width;
        NSCharacterSet* whiteSpaceCharacters = [NSCharacterSet 
			whitespaceAndNewlineCharacterSet];
		
        while([truncatedString sizeWithAttributes:inAttributes].width > 
			  targetWidth && truncatedStringLength)
        {
            truncatedStringLength--;
            while ([whiteSpaceCharacters characterIsMember:[truncatedString characterAtIndex:(truncatedStringLength -1)]])
            {
                // never truncate immediately after whitespace
                truncatedStringLength--;
            }
			
            truncatedString = [truncatedString substringToIndex:truncatedStringLength];
        }
		
        truncatedString = [truncatedString stringByAppendingString:ellipsisString];
    }
	
    return truncatedString;
}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += (_image ? [_image size].width : 0) + 3;
    return cellSize;
}

@end