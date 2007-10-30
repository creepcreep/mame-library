/* MLPreferencesController */

#import <Cocoa/Cocoa.h>

@interface MLPreferencesController : NSWindowController
{
	IBOutlet NSPopUpButton *mosxPopUpButton;
	IBOutlet NSPopUpButton *romsPopUpButton;
	IBOutlet NSPopUpButton *screenshotsPopUpButton;		
}
- (IBAction)setMAMEPath:(id)sender;
- (IBAction)setROMsPath:(id)sender;
- (IBAction)setScreenShotsPath:(id)sender;

- (NSString *)mosxPathTitle;
- (NSImage *)mosxPathImage;
- (NSString *)mosxPath;

- (NSString *)romsPathTitle;
- (NSImage *)romsPathImage;
- (NSString *)romsPath;

- (NSString *)screenshotsPathTitle;
- (NSImage *)screenshotsPathImage;
- (NSString *)screenshotsPath;
@end
