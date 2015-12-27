/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "ImageFile" class implementation.
*/

#import <Cocoa/Cocoa.h>
#import "AAPLImageFile.h"

@interface AAPLImageFile (Internals)
+ (NSOperationQueue *)previewLoadingOperationQueue;
//@property(copy) NSURL *url;
@property(copy) NSString *fileType;
@property(assign) unsigned long long fileSize;
@property(copy) NSDate *dateLastUpdated;
@property(strong) NSImage *previewImage;
@end

@implementation AAPLImageFile

+ (nonnull NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(nonnull NSString *)key {
    if ([key isEqual:@"localizedTypeDescription"]) {
        return [NSSet setWithObject:@"fileType"];
    } else {
        return [super keyPathsForValuesAffectingValueForKey:key];
    }
}

+ (NSOperationQueue *)previewLoadingOperationQueue {
    static NSOperationQueue *queue;
    if (queue == nil) {
        queue = [[NSOperationQueue alloc] init];
        queue.name = @"AAPLImageFile Preview Loading Queue";
    }
    return queue;
}

+ (NSDictionary *)demoTagNamesDictionary {
    static NSDictionary *demoTagNames;
    if (demoTagNames == nil) {
        demoTagNames = @{
             @"Abstract" : @[@"Texture"],
             @"Antelope Canyon" : @[@"Landscape", @"Texture"],
             @"Bahamas Aerial" : @[@"Landscape", @"Texture"],
             @"Beach" : @[@"Landscape", @"Water"],
             @"Blue Pond" : @[@"Flora", @"Landscape", @"Snow", @"Water"],
             @"Bristle Grass" : @[@"Flora", @"Landscape"],
             @"Brushes" : @[@"Texture"],
             @"Circles" : @[@"Texture"],
             @"Death Valley" : @[@"Landscape"],
             @"Desert" : @[@"Landscape", @"Texture"],
             @"Ducks on a Misty Pond" : @[@"Fauna", @"Landscape", @"Water"],
             @"Eagle & Waterfall" : @[@"Fauna", @"Landscape", @"Water"],
             @"Earth and Moon" : @[@"Space"],
             @"Earth Horizon" : @[@"Space"],
             @"Elephant" : @[@"Fauna", @"Landscape"],
             @"Flamingos" : @[@"Fauna", @"Landscape", @"Water"],
             @"Floating Ice" : @[@"Landscape", @"Snow", @"Water"]
        };
    }
    return demoTagNames;
}

+ (NSArray *)demoTagNamesForImageFileURL:(NSURL *)url {
    NSString *filenameWithoutExtension = [[url lastPathComponent] stringByDeletingPathExtension];
    return [[self demoTagNamesDictionary] objectForKey:filenameWithoutExtension];
}

- (id)initWithURL:(NSURL *)newURL {
    self = [super init];
    if (self) {
        self.url = newURL;

        // Get properties that we can obtain from the URL.
        id value;
        NSError *error;
        if ([self.url getResourceValue:&value forKey:NSURLTypeIdentifierKey error:&error]) {
            self.fileType = (NSString *)value;
        }
        if ([self.url getResourceValue:&value forKey:NSURLFileSizeKey error:&error]) {
            self.fileSize = ((NSNumber *)value).unsignedLongLongValue;
        }
        if ([self.url getResourceValue:&value forKey:NSURLContentModificationDateKey error:&error]) {
            self.dateLastUpdated = (NSDate *)value;
        }
        if ([self.url getResourceValue:&value forKey:NSURLTagNamesKey error:&error]) {
            self.tagNames = (NSArray *)value;
        }
        if (self.tagNames == nil) {
            // For Demo purposes, since the image files in "/Library/Desktop Pictures" don't have tags assigned to them, hardwire tagNames of our own.
            self.tagNames = [[self class] demoTagNamesForImageFileURL:self.url];
        }
    }
    return self;
}


#pragma mark File Properties

@synthesize url;
@synthesize fileType;
@synthesize fileSize;
@synthesize dateLastUpdated;

- (NSString *)filename {
    return self.url.lastPathComponent;
}

- (NSString *)filenameWithoutExtension {
    return self.filename.stringByDeletingPathExtension;
}

- (NSString *)localizedTypeDescription {
    NSString *type = self.fileType;
    return type ? [[NSWorkspace sharedWorkspace] localizedDescriptionForType:self.fileType] : nil;
}

- (NSString *)dimensionsDescription {
    return [NSString stringWithFormat:@"%ld x %ld", (long)(self.pixelsWide), (long)(self.pixelsHigh)];
}


#pragma mark Image Properties

- (NSInteger)pixelsWide {
    if (imageProperties == nil) {
        [self loadMetadata];
    }
    return [[imageProperties valueForKey:(NSString *)kCGImagePropertyPixelWidth] intValue];
}

- (NSInteger)pixelsHigh {
    if (imageProperties == nil) {
        [self loadMetadata];
    }
    return [[imageProperties valueForKey:(NSString *)kCGImagePropertyPixelHeight] intValue];
}

@synthesize previewImage;


#pragma mark Loading

/* Many kinds of image files contain prerendered thumbnail images that can be quickly loaded without having to decode the entire contents of the image file and reconstruct the full-size image.  The ImageIO framework's CGImageSource API provides a means to do this, using the CGImageSourceCreateThumbnailAtIndex() function.  For more information on CGImageSource objects and their capabilities, see the CGImageSource reference on the Apple Developer Connection website, at http://developer.apple.com/documentation/GraphicsImaging/Reference/CGImageSource/Reference/reference.html
*/
- (BOOL)createImageSource {
    
    if (imageSource == NULL) {
        // Compose absolute URL to file.
        NSURL *sourceURL = [[self url] absoluteURL];
        if (sourceURL == nil) {
            return NO;
        }
        
        // Create a CGImageSource from the URL.
        imageSource = CGImageSourceCreateWithURL((CFURLRef)sourceURL, NULL);
        if (imageSource == NULL) {
            return NO;
        }
        CFStringRef imageSourceType = CGImageSourceGetType(imageSource);
        if (imageSourceType == NULL) {
            CFRelease(imageSource);
            return NO;
        }
    }
    return imageSource ? YES : NO;
}

- (BOOL)loadMetadata {
    if (imageProperties == NULL) {
        
        // Get image properties.
        if (![self createImageSource]) {
            return NO;
        }
        
        // This code looks at the first image only.
        // To be truly general, we'd need to handle the possibility of an image source
        // having more than one image to offer us.
        //
        NSInteger index = 0;
        imageProperties = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSource, index, NULL));
    }
    
    // Return indicating success!
    return imageProperties ? YES : NO;
}

- (void)requestPreviewImage {
    if (self.previewImage == nil) {
        [[[self class] previewLoadingOperationQueue] addOperationWithBlock:^{
            if ([self createImageSource]) {
                NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                                         // Ask ImageIO to create a thumbnail from the file's image data, if it can't find
                                         // a suitable existing thumbnail image in the file.  We could comment out the following
                                         // line if only existing thumbnails were desired for some reason (maybe to favor
                                         // performance over being guaranteed a complete set of thumbnails).
                                         [NSNumber numberWithBool:YES], (NSString *)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                                         [NSNumber numberWithInt:160], (NSString *)kCGImageSourceThumbnailMaxPixelSize,
                                         nil];
                CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (CFDictionaryRef)options);
                if (thumbnail) {
                    NSImage *image = [[NSImage alloc] initWithCGImage:thumbnail size:NSZeroSize];
                    if (image) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            self.previewImage = image;
                        }];
                    }
                    CGImageRelease(thumbnail);
                }
            }
        }];
    }
}


#pragma mark Debugging Assistance

- (NSString *)description {
    return [NSString stringWithFormat:@"{ImageFile: %@, tags=%@}", self.url.absoluteString, self.tagNames];
}


#pragma mark Teardown

- (void)dealloc {
    if (imageSource) {
        CFRelease(imageSource);
    }
}

@end
