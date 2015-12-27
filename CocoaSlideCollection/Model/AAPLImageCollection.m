/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "ImageCollection" class implementation.
*/

#import "AAPLImageCollection.h"
#import "AAPLImageFile.h"
#import "AAPLTag.h"
#import "AAPLFileTreeWatcherThread.h"

NSString *imageFilesKey = @"imageFiles";

@implementation AAPLImageCollection

- (id)initWithRootURL:(NSURL *)newRootURL {
    
    self = [super init];
    if (self) {
        rootURL = [newRootURL copy];
        imageFiles = [[NSMutableArray alloc] init];
        imageFilesByURL = [[NSMutableDictionary alloc] init];
        untaggedImageFiles = [[NSMutableArray alloc] init];
        tags = [[NSMutableArray alloc] init];
        tagsByName = [[NSMutableDictionary alloc] init];
        fileTreeScanQueue = [[NSOperationQueue alloc] init];
        fileTreeScanQueue.name = @"AAPLImageCollection File Tree Scan Queue";
        
        /*
            Start watching the folder for changes.  Note that the "self" in this
            block creates a retain cycle.  To break it, we must
            -stopWatchingFolder when closing a browser window.
        */
        fileTreeWatcherThread = [[AAPLFileTreeWatcherThread alloc] initWithPath:[newRootURL path] changeHandler:^{
            
            // When we detect a change in the folder, scan it to find out what changed.
            [self startOrRestartFileTreeScan];
        }];
        [fileTreeWatcherThread start];
    }
    return self;
}


#pragma mark Property Accessors

@synthesize rootURL;
@synthesize imageFiles;
@synthesize untaggedImageFiles;


#pragma mark Querying the List of ImageFiles

- (AAPLImageFile *)imageFileForURL:(NSURL *)imageFileURL {
    return imageFilesByURL[imageFileURL];
}


#pragma mark Modifying the List of ImageFiles

- (void)addImageFile:(AAPLImageFile *)imageFile {
    [self insertImageFile:imageFile atIndex:imageFiles.count];
}

- (void)insertImageFile:(AAPLImageFile *)imageFile atIndex:(NSUInteger)index {
    
    // Add and update tags, based on the imageFile's tagNames.
    NSArray *tagNames = imageFile.tagNames;
    if (tagNames.count > 0) {
        for (NSString *tagName in imageFile.tagNames) {
            AAPLTag *tag = [self tagWithName:tagName];
            if (tag == nil) {
                tag = [self addTagWithName:tagName];
            }
            [tag insertImageFile:imageFile];
        }
    } else {
        // ImageFile has no tags, so add it to "untaggedImageFiles" instead.
        NSUInteger insertionIndex = [untaggedImageFiles indexOfObject:imageFile inSortedRange:NSMakeRange(0, untaggedImageFiles.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(AAPLImageFile *imageFile1, AAPLImageFile *imageFile2) {
            return [imageFile1.filenameWithoutExtension caseInsensitiveCompare:imageFile2.filenameWithoutExtension];
        }];
        if (insertionIndex == NSNotFound) {
            NSLog(@"Failed to find insertion index for untaggedImageFiles");
        } else {
            [untaggedImageFiles insertObject:imageFile atIndex:insertionIndex];
        }
    }
    
    // Insert the imageFile into our "imageFiles" array (in a KVO-compliant way).
    [[self mutableArrayValueForKey:imageFilesKey] insertObject:imageFile atIndex:index];

    // Add the imageFile into our "imageFilesByURL" dictionary.
    [imageFilesByURL setObject:imageFile forKey:imageFile.url];
}

- (void)removeImageFile:(AAPLImageFile *)imageFile {

    // Remove the imageFile from our "imageFiles" array (in a KVO-compliant way).
    [[self mutableArrayValueForKey:imageFilesKey] removeObject:imageFile];

    // Remove the imageFile from our "imageFilesByURL" dictionary.
    [imageFilesByURL removeObjectForKey:imageFile.url];

    // Remove the imageFile from the "imageFiles" arrays of its AAPLTags (if any).
    for (NSString *tagName in imageFile.tagNames) {
        AAPLTag *tag = [self tagWithName:tagName];
        if (tag) {
            [[tag mutableArrayValueForKey:@"imageFiles"] removeObject:imageFile];
        }
    }
}

- (void)removeImageFileAtIndex:(NSUInteger)index {
    AAPLImageFile *imageFile = [imageFiles objectAtIndex:index];
    [self removeImageFile:imageFile];
}

- (void)moveImageFileFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
    NSUInteger imageFilesCount = imageFiles.count;
    NSParameterAssert(fromIndex < imageFilesCount);
    NSParameterAssert(fromIndex < imageFilesCount);
    AAPLImageFile *imageFile = [imageFiles objectAtIndex:fromIndex];
    [self removeImageFileAtIndex:fromIndex];
    [self insertImageFile:imageFile atIndex:(toIndex <= fromIndex) ? toIndex : (toIndex - 1)];
}


#pragma mark Modifying the List of Tags

@synthesize tags;

- (AAPLTag *)tagWithName:(NSString *)name {
    return [tagsByName objectForKey:name];
}

- (AAPLTag *)addTagWithName:(NSString *)name {
    AAPLTag *tag = [self tagWithName:name];
    if (tag == nil) {
        tag = [[AAPLTag alloc] initWithName:name];
        if (tag) {
            [tagsByName setObject:tag forKey:name];
            
            // Binary-search and insert, in alphabetized tags array.
            NSUInteger insertionIndex = [tags indexOfObject:tag inSortedRange:NSMakeRange(0, [tags count]) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(AAPLTag *tag1, AAPLTag *tag2) {
                return [tag1.name caseInsensitiveCompare:tag2.name];
            }];
            if (insertionIndex == NSNotFound) {
                NSLog(@"** ERROR: Can't find insertion index in 'tags' array");
            } else {
                [tags insertObject:tag atIndex:insertionIndex];
            }
        }
    }
    return tag;
}


#pragma mark Finding Image Files

- (void)startOrRestartFileTreeScan {
    @synchronized(fileTreeScanQueue) {
        // Cancel any pending file tree scan operations.
        [self stopFileTreeScan];
        
        // Enqueue a new file tree scan operation.
        [fileTreeScanQueue addOperationWithBlock:^{

            /*
                Enumerate all of the image files in our given rootURL.  As we
                go, identify three groups of image files:

                (1) files that are in the catalog, but have since changed (the
                    file's modification date is later than its last-cached date)

                (2) files that exist on disk but are not yet in the catalog
                    (presumably the file was added and we should create an
                    ImageFile instance for it)

                (3) files that exist in the ImageCollection but not in the
                    folder (presumably the file was deleted and we should remove
                    the corresponding ImageFile instance)
            */
            NSMutableArray *filesToProcess = [self.imageFiles mutableCopy];
            AAPLImageFile *imageFile;
            NSMutableArray *filesChanged = [NSMutableArray array];
            NSMutableArray *urlsAdded = [NSMutableArray array];
            NSMutableArray *filesRemoved = [NSMutableArray array];
            
            NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:rootURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsRegularFileKey, NSURLTypeIdentifierKey, NSURLContentModificationDateKey, nil] options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants) errorHandler:^BOOL(NSURL *url, NSError *error) {
                NSLog(@"directoryEnumerator error: %@", error);
                return YES;
            }];
            for (NSURL *url in directoryEnumerator) {
                NSError *error;
                NSNumber *isRegularFile = nil;
                if ([url getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:&error]) {
                    if ([isRegularFile boolValue]) {
                        NSString *fileType = nil;
                        if ([url getResourceValue:&fileType forKey:NSURLTypeIdentifierKey error:&error]) {
                            if (UTTypeConformsTo((__bridge CFStringRef)fileType, CFSTR("public.image"))) {

                                // Look for a corresponding entry in the catalog.
                                imageFile = [self imageFileForURL:url];
                                if (imageFile != nil) {
                                    // Check whether file has changed.
                                    NSDate *modificationDate = nil;
                                    if ([url getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:&error]) {
                                        if ([modificationDate compare:imageFile.dateLastUpdated] == NSOrderedDescending) {
                                            [filesChanged addObject:imageFile];
                                        }
                                    }
                                    [filesToProcess removeObject:imageFile];
                                } else {
                                    // File was added.
                                    [urlsAdded addObject:url];
                                }
                            }
                        }
                    }
                }
            }

            // Check for images in the catalog for which no corresponding file was found.
            [filesRemoved addObjectsFromArray:filesToProcess];
            filesToProcess = nil;

            /*
                Perform our ImageCollection modifications on the main thread, so
                that corresponding KVO notifications and CollectionView updates will
                also happen on the main thread.
            */
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{

                // Remove ImageFiles for files we knew about that have disappeared.
                for (AAPLImageFile *imageFile in filesRemoved) {
                    [self removeImageFile:imageFile];
                }
                
                // Add ImageFiles for files we've newly discovered.
                for (NSURL *imageFileURL in urlsAdded) {
                    AAPLImageFile *imageFile = [[AAPLImageFile alloc] initWithURL:imageFileURL];
                    if (imageFile != nil) {
                        [self addImageFile:imageFile];
                    }
                }
            }];
        }];
    }
}

- (void)stopFileTreeScan {
    @synchronized(fileTreeScanQueue) {
        [fileTreeScanQueue cancelAllOperations];
    }
}

- (void)stopWatchingFolder {
    [fileTreeWatcherThread detachChangeHandler];
    [fileTreeWatcherThread cancel];
    fileTreeWatcherThread = nil;
}


#pragma mark Teardown

- (void)dealloc {
    [self stopWatchingFolder];
}

@end
