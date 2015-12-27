/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "ImageCollection" class declaration.
*/

#import <Cocoa/Cocoa.h>

@class AAPLImageFile;
@class AAPLTag;
@class AAPLFileTreeWatcherThread;

// An AAPLImageCollection encapsulates a list of AAPLImageFile objects, together with a rootURL that identifies the folder (if any) where we found them.  It also has a list of associated Tags, each of which can return the list of ImageFiles to which it's applied.
@interface AAPLImageCollection : NSObject
{
    NSURL *rootURL;                         // URL of folder in which we found our imageFiles
    AAPLFileTreeWatcherThread *fileTreeWatcherThread;   // thread that watches the folder for changes
    NSOperationQueue *fileTreeScanQueue;    // operation queue for asynchronous scans of the folder's contents

    NSMutableArray *imageFiles;             // a flat, ordered list of the collection's ImageFiles
    NSMutableDictionary *imageFilesByURL;   // an NSURL -> AAPLImageFile lookup table
    NSMutableArray *untaggedImageFiles;     // a flat, ordered list of the ImageFiles that aren't referenced by any AAPLTag

    NSMutableArray *tags;                   // a flat, alphabetical list of the collection's Tags
    NSMutableDictionary *tagsByName;        // an NSString -> AAPLTag lookup table
}
- (id)initWithRootURL:(NSURL *)newRootURL;


#pragma mark Properties

@property(readonly) NSURL *rootURL;
@property(readonly) NSArray *imageFiles;    // KVO observable


#pragma mark Querying the List of ImageFiles

- (AAPLImageFile *)imageFileForURL:(NSURL *)imageFileURL;


#pragma mark Modifying the List of ImageFiles

- (void)addImageFile:(AAPLImageFile *)imageFile;
- (void)insertImageFile:(AAPLImageFile *)imageFile atIndex:(NSUInteger)index;
- (void)removeImageFile:(AAPLImageFile *)imageFile;
- (void)removeImageFileAtIndex:(NSUInteger)index;
- (void)moveImageFileFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;


#pragma mark Modifying the List of Tags

@property(readonly) NSArray<AAPLTag *> *tags;
- (AAPLTag *)tagWithName:(NSString *)name;
- (AAPLTag *)addTagWithName:(NSString *)name;

@property(readonly) NSArray<AAPLImageFile *> *untaggedImageFiles;


#pragma mark Finding Image Files

- (void)startOrRestartFileTreeScan;
- (void)stopFileTreeScan;

- (void)stopWatchingFolder;

@end

extern NSString *imageFilesKey;
