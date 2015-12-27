/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "LoopLayout" class implementation.
*/

#import "AAPLLoopLayout.h"

@implementation AAPLLoopLayout

- (void)prepareLayout {
    [super prepareLayout];
    
    CGFloat halfItemWidth = 0.5 * itemSize.width;
    CGFloat halfItemHeight = 0.5 * itemSize.height;
    CGFloat radiusInset = sqrt(halfItemWidth * halfItemWidth + halfItemHeight * halfItemHeight);
    loopCenter = NSMakePoint(NSMidX(box), NSMidY(box));
    loopSize = NSMakeSize(0.5 * (box.size.width - 2.0 * radiusInset), 0.5 * (box.size.height - 2.0 * radiusInset));
}

- (NSCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger count = [[self collectionView] numberOfItemsInSection:0];
    if (count == 0) {
        return nil;
    }
    
    NSUInteger itemIndex = [indexPath item];
    CGFloat angleInRadians = ((CGFloat)itemIndex / (CGFloat)count) * (2.0 * M_PI);
    NSPoint subviewCenter;
    subviewCenter.x = loopCenter.x + loopSize.width * cos(angleInRadians);
    subviewCenter.y = loopCenter.y + loopSize.height * sin(2.0 * angleInRadians);
    NSRect itemFrame = NSMakeRect(subviewCenter.x - 0.5 * itemSize.width, subviewCenter.y - 0.5 * itemSize.height, itemSize.width, itemSize.height);
    
    NSCollectionViewLayoutAttributes *attributes = [[[self class] layoutAttributesClass] layoutAttributesForItemWithIndexPath:indexPath];
    [attributes setFrame:NSRectToCGRect(itemFrame)];
    [attributes setZIndex:[indexPath item]];
    return attributes;
}

@end
