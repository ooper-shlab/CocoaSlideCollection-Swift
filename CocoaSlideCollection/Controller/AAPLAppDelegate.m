/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the application delegate implementation.
*/

#import "AAPLAppDelegate.h"
#import "AAPLBrowserWindowController.h"

@implementation AAPLAppDelegate

/*
    Given a file:// URL that points to a folder, opens a new browser window that
    displays the image files in that folder.
*/
- (void)openBrowserWindowForFolderURL:(NSURL *)folderURL {
    AAPLBrowserWindowController *browserWindowController = [[AAPLBrowserWindowController alloc] initWithRootURL:folderURL];
    if (browserWindowController) {
        [browserWindowController showWindow:self];

        /*
            Add browserWindowController to browserWindowControllers, to keep it
            alive.
        */
        if (browserWindowControllers == nil) {
            browserWindowControllers = [[NSMutableSet alloc] init];
        }
        [browserWindowControllers addObject:browserWindowController];
        
        /*
            Watch for the window to be closed, so we can let it and its
            controller go.
        */
        NSWindow *browserWindow = [browserWindowController window];
        if (browserWindow) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(browserWindowWillClose:) name:NSWindowWillCloseNotification object:browserWindow];
        }
    }
}

/*
    Action method invoked by the "File" -> "Open Browser..." menu command.
    Prompts the user to choose a folder, using a standard Open panel, then opens
    a browser window for that folder using the method above.
*/
- (IBAction)openBrowserWindow:(id)sender {
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.prompt = @"Choose";
    openPanel.message = @"Choose a directory containing images:";
    openPanel.title = @"Choose Directory";
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    NSArray *pictureDirectories = NSSearchPathForDirectoriesInDomains(NSPicturesDirectory, NSUserDomainMask, YES);
    openPanel.directoryURL = [NSURL fileURLWithPath:pictureDirectories[0]];

    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            [self openBrowserWindowForFolderURL:openPanel.URLs[0]];
        }
    }];
}

// When a browser window is closed, release its BrowserWindowController.
- (void)browserWindowWillClose:(NSNotification *)notification {
    NSWindow *browserWindow = (NSWindow *)(notification.object);
    [browserWindowControllers removeObject:browserWindow.delegate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:browserWindow];
}

#pragma mark NSApplicationDelegate Methods

// Browse a default folder on launch.
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self openBrowserWindowForFolderURL:[NSURL fileURLWithPath:@"/Library/Desktop Pictures"]];
}

@end
