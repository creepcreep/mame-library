//
//  MLSourceListSplitView.h
//  MAME Library
//
//  Created by Johnnie Walker on 24/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KFSplitView.h"

@interface MLSourceListSplitView : KFSplitView <KFSplitViewDelegate> {
	NSView *topSubview;
	NSView *bottomSubview;
}

@end
