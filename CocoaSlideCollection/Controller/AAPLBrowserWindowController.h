/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the browser window controller declaration.
*/

#import <Cocoa/Cocoa.h>

@class AAPLImageCollection;

typedef enum {
    SlideLayoutKindCircular = 0,
    SlideLayoutKindLoop = 1,
    SlideLayoutKindScatter = 2,
    SlideLayoutKindWrapped = 3
} SlideLayoutKind;

/*
    Each browser window is managed by a AAPLBrowserWindowController, which
    serves as its CollectionView's dataSource and delegate.  (The
    CollectionView's dataSource and delegate outlets are wired up in
    BrowserWindow.xib, so there is no need to set these properties in code.)
*/
@interface AAPLBrowserWindowController : NSWindowController <NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout>
{
    // Model
    NSURL *rootURL;                                         // URL of the folder whose image files the browser is displaying
    AAPLImageCollection *imageCollection;                   // the ImageFiles we found in the folder, which we can access as a flat list or grouped by AAPLTag

    // Views
    IBOutlet NSCollectionView *__weak imageCollectionView;  // a CollectionView that displays items ("slides") representing the image files
    IBOutlet NSTextField *__weak statusTextField;           // a TextField that shows informative status

    // UI State
    SlideLayoutKind layoutKind;                             // what kind of layout to use, per the above SlideLayoutKind enumeration
    BOOL groupByTag;                                        // YES if our imageCollectionView should show its items grouped by tag, with header and footer views (usable with Wrapped layout only)
    BOOL autoUpdateResponseSuspended;                       // YES when we want to suppress our usual automatic KVO response to assets coming and going
    NSSet<NSIndexPath *> *indexPathsOfItemsBeingDragged;    // when our imageCollectionView is the source for a drag operation, this array of NSIndexPaths identifies the items that are being dragged within or out of it
}

// Initializes a browser window that's pointed at the given folder URL.
- (id)initWithRootURL:(NSURL *)newRootURL;


#pragma mark Outlets

@property(weak) IBOutlet NSCollectionView *imageCollectionView;
@property(weak) IBOutlet NSTextField *statusTextField;


#pragma mark Actions

- (IBAction)refresh:(id)sender;


#pragma mark Properties

@property SlideLayoutKind layoutKind;
@property BOOL groupByTag;

@end
