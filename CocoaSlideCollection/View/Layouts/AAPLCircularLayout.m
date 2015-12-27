/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "CircularLayout" class implementation.
*/

#import "AAPLCircularLayout.h"

@implementation AAPLCircularLayout

- (void)prepareLayout {
    [super prepareLayout];
    
    CGFloat halfItemWidth = 0.5 * itemSize.width;
    CGFloat halfItemHeight = 0.5 * itemSize.height;
    CGFloat radiusInset = sqrt(halfItemWidth * halfItemWidth + halfItemHeight * halfItemHeight);
    circleCenter = NSMakePoint(NSMidX(box), NSMidY(box));
    circleRadius = MIN(box.size.width, box.size.height) * 0.5 - radiusInset;
}

- (NSCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger count = [[self collectionView] numberOfItemsInSection:0];
    if (count == 0) {
        return nil;
    }
    
    NSUInteger itemIndex = [indexPath item];
    CGFloat angleInRadians = ((CGFloat)itemIndex / (CGFloat)count) * (2.0 * M_PI);
    NSPoint subviewCenter;
    subviewCenter.x = circleCenter.x + circleRadius * cos(angleInRadians);
    subviewCenter.y = circleCenter.y + circleRadius * sin(angleInRadians);
    NSRect itemFrame = NSMakeRect(subviewCenter.x - 0.5 * itemSize.width, subviewCenter.y - 0.5 * itemSize.height, itemSize.width, itemSize.height);
    
    NSCollectionViewLayoutAttributes *attributes = [[[self class] layoutAttributesClass] layoutAttributesForItemWithIndexPath:indexPath];
    [attributes setFrame:NSRectToCGRect(itemFrame)];
    [attributes setZIndex:itemIndex];
    return attributes;
}

@end
