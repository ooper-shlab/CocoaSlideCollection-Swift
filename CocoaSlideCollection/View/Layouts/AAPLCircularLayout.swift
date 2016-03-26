//
//  AAPLCircularLayout.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/26.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    This is the "CircularLayout" class declaration.
*/

import Cocoa

// Positions items in a circle, within the available area.
@objc(AAPLCircularLayout)
class AAPLCircularLayout: AAPLSlideLayout {
    private var circleCenter: NSPoint = NSPoint()
    private var circleRadius: CGFloat = 0.0
    
    override func prepareLayout() {
        super.prepareLayout()
        
        let halfItemWidth = 0.5 * itemSize.width
        let halfItemHeight = 0.5 * itemSize.height
        let radiusInset = sqrt(halfItemWidth * halfItemWidth + halfItemHeight * halfItemHeight)
        circleCenter = NSMakePoint(NSMidX(box), NSMidY(box))
        circleRadius = min(box.size.width, box.size.height) * 0.5 - radiusInset
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> NSCollectionViewLayoutAttributes? {
        guard let count = self.collectionView?.numberOfItemsInSection(0) where count != 0 else {
            return nil
        }
        
        let itemIndex = indexPath.item
        let angleInRadians = (CGFloat(itemIndex) / CGFloat(count)) * (2.0 * CGFloat(M_PI))
        var subviewCenter: NSPoint = NSPoint()
        subviewCenter.x = circleCenter.x + circleRadius * cos(angleInRadians)
        subviewCenter.y = circleCenter.y + circleRadius * sin(angleInRadians)
        let itemFrame = NSMakeRect(subviewCenter.x - 0.5 * itemSize.width, subviewCenter.y - 0.5 * itemSize.height, itemSize.width, itemSize.height)
        
        let attributes = (self.dynamicType.layoutAttributesClass() as! NSCollectionViewLayoutAttributes.Type).init(forItemWithIndexPath: indexPath)
        attributes.frame = NSRectToCGRect(itemFrame)
        attributes.zIndex = itemIndex
        return attributes
    }
    
}