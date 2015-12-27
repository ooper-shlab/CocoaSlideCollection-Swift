/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "Tag" class implementation.
*/

#import "AAPLTag.h"
#import "AAPLImageFile.h"

@implementation AAPLTag

- (id)initWithName:(NSString *)newName {
    self = [super init];
    if (self) {
        name = [newName copy];
        imageFiles = [[NSMutableArray alloc] init];
    }
    return self;
}

@synthesize name;
@synthesize imageFiles;

- (void)insertImageFile:(AAPLImageFile *)imageFile {
    NSUInteger insertionIndex = [imageFiles indexOfObject:imageFile inSortedRange:NSMakeRange(0, [imageFiles count]) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(AAPLImageFile *imageFile1, AAPLImageFile *imageFile2) {
        return [imageFile1.filenameWithoutExtension caseInsensitiveCompare:imageFile2.filenameWithoutExtension];
    }];
    if (insertionIndex == NSNotFound) {
        NSLog(@"** Couldn't determine insertionIndex for imageFiles array");
    } else {
        [imageFiles insertObject:imageFile atIndex:insertionIndex];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"{Tag: %@}", self.name];
}

@end
