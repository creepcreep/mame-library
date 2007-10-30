//
//  MAME_Library_AppDelegate.h
//  MAME Library
//
//  Created by Johnnie Walker on 05/01/2007.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>
#import "MUPhotoView.h"

@class MLHeaderView;
@class MLGame;
@class MLCollection;
@class MAMEXMLParser;
@class MLHistoryParser;
@class MLOutlineViewDragController;
@class KFSplitView;
@class MLPreferencesController;
@interface MAME_Library_AppDelegate : NSObject 
{
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *debugWindow;
    IBOutlet NSPanel *inspectorPanel;

    IBOutlet NSArrayController *gamesArrayController;
    IBOutlet NSArrayController *availableGamesArrayController;
    IBOutlet NSArrayController *collectionsArrayController;		
	IBOutlet NSTreeController *collectionsTreeController;

	IBOutlet MLOutlineViewDragController *outlineViewDragController;
	
	IBOutlet NSUserDefaultsController *defaultsController;
    
    IBOutlet MUPhotoView *photoView;
    IBOutlet NSSlider *photoSizeSlider;

    IBOutlet NSMenuItem *showAllGamesMenuItem;
    IBOutlet NSMenuItem *showAvailableGamesMenuItem;
    IBOutlet NSMenuItem *showPlayableGamesMenuItem;		
    IBOutlet NSMenuItem *toggleClonesMenuItem;	
    IBOutlet NSMenuItem *switchViewMenuItem;	

	IBOutlet MLPreferencesController *preferencesController;

    IBOutlet NSMenu *sortGamesMenu;	

	IBOutlet KFSplitView *splitView;
	IBOutlet KFSplitView *sourceListSplitView;	

	IBOutlet NSView *sourceOutlineView;
	IBOutlet NSView *sourceOutlineViewPlaceHolder;	
	IBOutlet NSView *artworkView;	
	IBOutlet NSView *artworkViewPlaceHolder;		

	IBOutlet NSView *sourceView;
	IBOutlet NSView *sourceViewPlaceHolder;	
	IBOutlet NSView *contentView;	
	IBOutlet NSView *contentViewPlaceHolder;		

	IBOutlet NSScrollView *scrollView;    
	IBOutlet NSTabView *tabView;
	IBOutlet NSTableView *tableView;
	
	IBOutlet NSLevelIndicator *myRatingIndicator;
	
	IBOutlet NSMatrix *viewModeMatrix;	
    IBOutlet NSTableColumn *imagesTableColumn;
	
	IBOutlet MLHeaderView *gridHeaderView;
	
	NSNumber *_sortDescending;
	
	NSImage *missingImage;
	NSImage *overlayImage;
	
	NSString *missingImagePath;

	NSString *sortKey;
	NSString *sortKeyTitle;	
	NSArray *sortDescriptors;

	MLCollection *selectedCollection;

	NSPredicate *collectionPredicate;	
//	NSPredicate *gameListPredicate;
//	NSPredicate *showClonesPredicate;	
	
//	NSMutableArray *ROMs;
	// NSMutableArray *availableGames;	

    NSPersistentStoreCoordinator *importStoreCoordinator;	
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	
	NSMutableDictionary *_sortKeyTitles;
	
	MAMEXMLParser *_parser;
	MLHistoryParser *_historyParser;
	
	NSString *historyDownloadPath;
	
	NSTask *mameTask;	
}

- (void)setupAndShowMainWindow;

- (IBAction)checkForHistoryDatUpdates:(id)sender;

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
- (NSString *)cacheFolder;

- (NSArray *)allGamesInStore;

- (BOOL)requestMAMEDataUpdate;

- (IBAction)getMAMEOSX:(id)sender;

- (IBAction)findNewRoms:sender;
- (IBAction)findScreenshots:sender;
- (IBAction)importFromMAME:sender;
- (void)importFromMAMEWithUserInfo:(NSDictionary *)userinfo;

- (IBAction)getInfo:sender;

- (IBAction)saveAction:sender;

- (IBAction)tableViewDoubleClick:(id)sender;
- (IBAction)launchSelectedGame:(id)sender;

- (IBAction)showDebugWindow:sender;
- (IBAction)switchView:(id)sender;

- (void)setSortDescending:(id)value;
- (IBAction)sortAscending:(id)sender;
- (IBAction)sortDescending:(id)sender;
- (IBAction)setGamesControllerSortDescriptors:(id)sender;

- (IBAction)setRating:(id)sender;

- (void)updateSortDescriptors;

- (IBAction)toggleArtwork:(id)sender;
- (IBAction)toggleClones:(id)sender;
- (IBAction)setGamesControllerPredicate:(id)sender;
- (void)setGamesPredicate;

- (IBAction)forceFetch:(id)sender;
- (IBAction)revealInFinder:(id)sender;

- (IBAction)showFAQ:(id)sender;
- (IBAction)showReleaseNotes:(id)sender;
- (IBAction)visitWebsite:(id)sender;

- (IBAction)import:(id)sender;
- (IBAction)export:(id)sender;
- (BOOL)importUserInfoFromPath:(NSString *)userInfoPath;
- (void)importCollectionsFromUserinfo:(NSDictionary *)userInfo;
- (BOOL)exportUserInfoToPath:(NSString *)userInfoPath;

- (NSDictionary *)userInfoFromManagedObjectContext:(NSManagedObjectContext *)context;

- (NSString *)mameVersionString;

- (void)getGameTitles;
- (void)launchGame:(MLGame *)game;

- (BOOL)canRemove;
- (void)setSelectedCollection:(MLCollection *)collection;

- (NSData *)pasteboardDataForItems:(NSArray *)items;

@end
