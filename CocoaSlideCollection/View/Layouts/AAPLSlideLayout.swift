//
//  AAPLSlideLayout.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/26.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    This is the "SlideLayout" class declaration.
*/

import Cocoa

let X_PADDING: CGFloat = 10.0
let Y_PADDING: CGFloat = 10.0

// The base class for our custom slide layouts.  It provides a foundation for layouts that show all of a CollectionView's items within the CollectionView's visibleRect (so that no scrolling is required).
@objc(AAPLSlideLayout)
class AAPLSlideLayout: NSCollectionViewLayout {
    var box: NSRect = NSRect()
    var itemSize: NSSize
    
    override init() {
        itemSize = NSMakeSize(SLIDE_WIDTH, SLIDE_HEIGHT)
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var collectionViewContentSize: NSSize {
        let clipBounds = self.collectionView?.superview?.bounds ?? NSRect()
        return clipBounds.size // Lay our slides out within the available area.
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
        return true // Our custom SlideLayouts show all items within the CollectionView's visible rect, and must recompute their layouts for a good fit when that rect changes.
    }
    
    override func prepare() {
        super.prepare()
        
        // Inset by (X_PADDING,Y_PADDING) to precompute the box we need to fix the slides in.
        let collectionViewContentSize = self.collectionViewContentSize
        box = NSInsetRect(NSMakeRect(0, 0, collectionViewContentSize.width, collectionViewContentSize.height), X_PADDING, Y_PADDING)
    }
    
    // A layout derived from this base class always displays all items, within the visible rectangle.  So we can implement -layoutAttributesForElementsInRect: quite simply, by enumerating all item index paths and obtaining the -layoutAttributesForItemAtIndexPath: for each.  Our subclasses then just have to implement -layoutAttributesForItemAtIndexPath:.
    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        let itemCount = self.collectionView?.numberOfItems(inSection: 0) ?? 0
        var layoutAttributesArray: [NSCollectionViewLayoutAttributes] = []
        layoutAttributesArray.reserveCapacity(itemCount)
        for index in 0..<itemCount {
            let indexPath = IndexPath(item: index, section: 0)
            if let layoutAttributes = self.layoutAttributesForItem(at: indexPath) {
                layoutAttributesArray.append(layoutAttributes)
            }
        }
        return layoutAttributesArray
    }
    
}
