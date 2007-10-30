//
//  MLGamesTableView.h
//  MAME Library
//
//  Created by Johnnie Walker on 06/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MLGamesTableView : NSTableView {
	IBOutlet NSArrayController *availableGamesArrayController;
}

@end
