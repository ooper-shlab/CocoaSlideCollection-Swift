//
//  AAPLLoopLayout.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/26.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    This is the "LoopLayout" class declaration.
*/

import Cocoa

// Positions items in an "infinity"-shaped loop, within the available area.
@objc(AAPLLoopLayout)
class AAPLLoopLayout: AAPLSlideLayout {
    private var loopCenter: NSPoint = NSPoint()
    private var loopSize: NSSize = NSSize()
    
    override func prepare() {
        super.prepare()
        
        let halfItemWidth = 0.5 * itemSize.width
        let halfItemHeight = 0.5 * itemSize.height
        let radiusInset = sqrt(halfItemWidth * halfItemWidth + halfItemHeight * halfItemHeight)
        loopCenter = NSMakePoint(NSMidX(box), NSMidY(box))
        loopSize = NSMakeSize(0.5 * (box.size.width - 2.0 * radiusInset), 0.5 * (box.size.height - 2.0 * radiusInset))
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        
        guard let count = self.collectionView?.numberOfItems(inSection: 0) , count != 0 else {
            return nil
        }
        
        let itemIndex = indexPath.item
        let angleInRadians = (CGFloat(itemIndex) / CGFloat(count)) * (2.0 * .pi)
        var subviewCenter: NSPoint = NSPoint()
        subviewCenter.x = loopCenter.x + loopSize.width * cos(angleInRadians)
        subviewCenter.y = loopCenter.y + loopSize.height * sin(2.0 * angleInRadians)
        let itemFrame = NSMakeRect(subviewCenter.x - 0.5 * itemSize.width, subviewCenter.y - 0.5 * itemSize.height, itemSize.width, itemSize.height)
        
        let attributes = (type(of: self).layoutAttributesClass as! NSCollectionViewLayoutAttributes.Type).init(forItemWith: indexPath)
        attributes.frame = NSRectToCGRect(itemFrame)
        attributes.zIndex = indexPath.item
        return attributes
    }
    
}
