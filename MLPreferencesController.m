#import "MLPreferencesController.h"

@implementation MLPreferencesController

- (IBAction)showWindow:(id)sender
{
	if ([self window] == nil) {
		[NSBundle loadNibNamed:@"Preferences" owner:self];
	}

	[super showWindow:sender];	
}

- (NSString *)mosxPathTitle
{
	return [[[self mosxPath] lastPathComponent] stringByDeletingPathExtension];
}

- (NSImage *)mosxPathImage
{
	NSString *mosxPath;
	NSImage *mosxImage;
	
	if (mosxPath = [self mosxPath]) {
		mosxImage = [[NSWorkspace sharedWorkspace] iconForFile:[self mosxPath]];
		if (mosxImage) {
			[mosxImage setSize:NSMakeSize(16,16)];
			return mosxImage;	
		}		
	}
	
	return nil;
}

- (NSString *)mosxPath
{
	return [[NSUserDefaults standardUserDefaults] valueForKey:@"MLMAMEPath"];
}

- (NSString *)romsPathTitle
{
	return [[[self romsPath] lastPathComponent] stringByDeletingPathExtension];
}

- (NSImage *)romsPathImage
{
	NSString *path;
	NSImage *image;
	
	if (path = [self romsPath]) {
		image = [[NSWorkspace sharedWorkspace] iconForFile:path];
		if (image) {
			[image setSize:NSMakeSize(16,16)];
			return image;	
		}		
	}
	
	return nil;
}

- (NSString *)romsPath
{
	return [[NSUserDefaults standardUserDefaults] valueForKey:@"MLROMsPath"];
}

- (NSString *)screenshotsPathTitle
{
	return [[[self screenshotsPath] lastPathComponent] stringByDeletingPathExtension];
}

- (NSImage *)screenshotsPathImage
{
	NSString *path;
	NSImage *image;
	
	if (path = [self screenshotsPath]) {
		image = [[NSWorkspace sharedWorkspace] iconForFile:path];
		if (image) {
			[image setSize:NSMakeSize(16,16)];
			return image;	
		}		
	}
	
	return nil;
}

- (NSString *)screenshotsPath
{
	return [[NSUserDefaults standardUserDefaults] valueForKey:@"MLScreenShotsPath"];
}

- (IBAction)setMAMEPath:(id)sender
{

	NSString *currentPath = [self mosxPath];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	if ([openPanel runModalForDirectory:[currentPath stringByDeletingLastPathComponent] file:[currentPath lastPathComponent] types:[NSArray arrayWithObject:NSApplicationFileType]]) {
		NSArray *filenames = [openPanel filenames];
		NSString *newPath;
		if (newPath = [filenames objectAtIndex:0]) {
			[self willChangeValueForKey:@"mosxPath"];
			[self willChangeValueForKey:@"mosxPathTitle"];			
			[self willChangeValueForKey:@"mosxPathImage"];						
			[[NSUserDefaults standardUserDefaults] setValue:newPath forKey:@"MLMAMEPath"];
			[self didChangeValueForKey:@"mosxPath"];
			[self didChangeValueForKey:@"mosxPathTitle"];
			[self didChangeValueForKey:@"mosxPathImage"];						
		}
	}
	
	[mosxPopUpButton selectItemAtIndex:0];
}

- (IBAction)setROMsPath:(id)sender
{

	NSString *currentPath = [self romsPath];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:TRUE];	
	if ([openPanel runModalForDirectory:[currentPath stringByDeletingLastPathComponent] file:[currentPath lastPathComponent] types:[NSArray arrayWithObject:NSDirectoryFileType]]) {
		NSArray *filenames = [openPanel filenames];
		NSString *newPath;
		if (newPath = [filenames objectAtIndex:0]) {
			[self willChangeValueForKey:@"romsPath"];
			[self willChangeValueForKey:@"romsPathTitle"];			
			[self willChangeValueForKey:@"romsPathImage"];						
			[[NSUserDefaults standardUserDefaults] setValue:newPath forKey:@"MLROMsPath"];
			[self didChangeValueForKey:@"romsPath"];
			[self didChangeValueForKey:@"romsPathTitle"];
			[self didChangeValueForKey:@"romsPathImage"];						
		}
	}
	
	[romsPopUpButton selectItemAtIndex:0];	
}

- (IBAction)setScreenShotsPath:(id)sender
{

	NSString *currentPath = [[NSUserDefaults standardUserDefaults] valueForKey:@"MLScreenShotsPath"];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:TRUE];		
	if ([openPanel runModalForDirectory:[currentPath stringByDeletingLastPathComponent] file:[currentPath lastPathComponent] types:[NSArray arrayWithObject:NSDirectoryFileType]]) {
		NSArray *filenames = [openPanel filenames];
		NSString *newPath;
		if (newPath = [filenames objectAtIndex:0]) {
			[self willChangeValueForKey:@"screenshotsPath"];
			[self willChangeValueForKey:@"screenshotsPathTitle"];			
			[self willChangeValueForKey:@"screenshotsPathImage"];								
			[[NSUserDefaults standardUserDefaults] setValue:newPath forKey:@"MLScreenShotsPath"];
			[self didChangeValueForKey:@"screenshotsPath"];
			[self didChangeValueForKey:@"screenshotsPathTitle"];
			[self didChangeValueForKey:@"screenshotsPathImage"];									
		}
	}
	
	[screenshotsPopUpButton selectItemAtIndex:0];
}

@end
