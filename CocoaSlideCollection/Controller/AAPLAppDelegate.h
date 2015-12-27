/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the application delegate declaration.
*/

#import <Cocoa/Cocoa.h>

/*
    The application delegate opens a browser window for
    "/Library/Desktop Pictures" on launch, and handles requests to open
    additional browser windows.
*/

@interface AAPLAppDelegate : NSObject <NSApplicationDelegate>
{
    NSMutableSet *browserWindowControllers;
}

// CocoaSlideCollection's "File" -> "Browse Folder..." (Cmd+O) menu item sends this.
- (IBAction)openBrowserWindow:(id)sender;

@end
