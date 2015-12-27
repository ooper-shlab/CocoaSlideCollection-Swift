/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "SlideLayout" class implementation.
*/

#import "AAPLSlideLayout.h"
#import "AAPLSlideCarrierView.h"    // for SLIDE_WIDTH, SLIDE_HEGIHT

@implementation AAPLSlideLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        itemSize = NSMakeSize(SLIDE_WIDTH, SLIDE_HEIGHT);
    }
    return self;
}

- (NSSize)collectionViewContentSize {
    NSRect clipBounds = [[[self collectionView] superview] bounds];
    return clipBounds.size; // Lay our slides out within the available area.
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(NSRect)newBounds {
    return YES; // Our custom SlideLayouts show all items within the CollectionView's visible rect, and must recompute their layouts for a good fit when that rect changes.
}

- (void)prepareLayout {
    [super prepareLayout];
    
    // Inset by (X_PADDING,Y_PADDING) to precompute the box we need to fix the slides in.
    CGSize collectionViewContentSize = [self collectionViewContentSize];
    box = NSInsetRect(NSMakeRect(0, 0, collectionViewContentSize.width, collectionViewContentSize.height), X_PADDING, Y_PADDING);
}

// A layout derived from this base class always displays all items, within the visible rectangle.  So we can implement -layoutAttributesForElementsInRect: quite simply, by enumerating all item index paths and obtaining the -layoutAttributesForItemAtIndexPath: for each.  Our subclasses then just have to implement -layoutAttributesForItemAtIndexPath:.
- (NSArray *)layoutAttributesForElementsInRect:(NSRect)rect {
    NSInteger itemCount = [[self collectionView] numberOfItemsInSection:0];
    NSMutableArray *layoutAttributesArray = [NSMutableArray arrayWithCapacity:itemCount];
    for (NSInteger index = 0; index < itemCount; index++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        NSCollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        if (layoutAttributes) {
            [layoutAttributesArray addObject:layoutAttributes];
        }
    }
    return layoutAttributesArray;
}

@end
