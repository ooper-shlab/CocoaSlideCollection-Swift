/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "SlideLayout" class declaration.
*/

#import <Cocoa/Cocoa.h>

#define X_PADDING        10.0
#define Y_PADDING        10.0

// The base class for our custom slide layouts.  It provides a foundation for layouts that show all of a CollectionView's items within the CollectionView's visibleRect (so that no scrolling is required).
@interface AAPLSlideLayout : NSCollectionViewLayout
{
    NSRect box;
    NSSize itemSize;
}
@end
