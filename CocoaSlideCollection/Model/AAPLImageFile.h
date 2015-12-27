/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "ImageFile" class declaration.
*/

#import <Foundation/Foundation.h>

// This is our Model representation of an image file.  It provides access to the file's properties and its contained image, including pixel dimensions and a thumbnail preview.
@interface AAPLImageFile : NSObject
{
    CGImageSourceRef imageSource;           // NULL until metadata is loaded
    NSDictionary *imageProperties;          // nil until metadata is loaded
}

- (id)initWithURL:(NSURL *)newURL;


#pragma mark File Properties

@property(copy) NSURL *url;
@property(copy) NSString *fileType;
@property unsigned long long fileSize;
@property(copy) NSDate *dateLastUpdated;
@property(copy) NSArray *tagNames;

@property(readonly) NSString *filename;
@property(readonly) NSString *filenameWithoutExtension;
@property(readonly) NSString *localizedTypeDescription;
@property(readonly) NSString *dimensionsDescription;


#pragma mark Image Properties

@property(readonly) NSInteger pixelsWide;
@property(readonly) NSInteger pixelsHigh;

@property(strong) NSImage *previewImage;


#pragma mark Loading

// These are triggered automatically the first time relevant properties are requested, but can be invoked explicitly to force loading earlier.
- (BOOL)loadMetadata;

- (void)requestPreviewImage;

@end
