/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "Tag" class declaration.
*/

#import <Foundation/Foundation.h>

@class AAPLImageFile;

// An AAPLTag is a label string that can be applied to ImageFiles.  An AAPLImageCollection has a list of Tags, each of which has associated ImageFiles.
@interface AAPLTag : NSObject
{
    NSString *name;                 // the tag string (e.g. "Vacation")
    NSMutableArray *imageFiles;     // the ImageFiles that have this tag, ordered for display using our desired sort
}
- initWithName:(NSString *)newName;

@property(readonly) NSString *name;

@property(readonly) NSArray<AAPLImageFile *> *imageFiles;

- (void)insertImageFile:(AAPLImageFile *)imageFile;

@end
