//
//  AAPLWrappedLayout.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/26.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    This is the "WrappedLayout" class declaration.
*/

import Cocoa

// Flows items in rows.
@objc(AAPLWrappedLayout)
class AAPLWrappedLayout: NSCollectionViewFlowLayout {
    
    override init() {
        super.init()
        self.itemSize = NSMakeSize(SLIDE_WIDTH, SLIDE_HEIGHT)
        self.minimumInteritemSpacing = X_PADDING
        self.minimumLineSpacing = Y_PADDING
        self.sectionInset = NSEdgeInsetsMake(Y_PADDING, X_PADDING, Y_PADDING, X_PADDING)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        attributes?.zIndex = indexPath.item
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        let layoutAttributesArray = super.layoutAttributesForElements(in: rect)
        for attributes in layoutAttributesArray {
            attributes.zIndex = attributes.indexPath?.item ?? 0
        }
        return layoutAttributesArray
    }
    
}
