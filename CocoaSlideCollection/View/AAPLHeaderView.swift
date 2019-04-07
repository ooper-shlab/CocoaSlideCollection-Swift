//
//  AAPLHeaderView.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/26.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    This is the "HeaderView" class declaration.
*/

import Cocoa

@objc(AAPLHeaderView)
class AAPLHeaderView: NSView, NSCollectionViewElement {
    
    // Returns the HeaderView's title NSTextField (if it currently has one).
    var titleTextField: NSTextField? {
        for view in self.subviews {
            if let textField = view as? NSTextField {
                return textField
            }
        }
        return nil
    }
    
    // Draws the HeaderView's background: semitransparent white fill, with highlight and shadow lines at top and bottom.
    override func draw(_ dirtyRect: NSRect) {
        // Fill with semitransparent white.
        NSColor(calibratedWhite: 0.95, alpha: 0.7).set()
        dirtyRect.fill(using: .sourceOver)
        
        // Fill bottom and top edges with semitransparent gray.
        NSColor(calibratedWhite: 0.75, alpha: 0.8).set()
        let bounds = self.bounds
        var bottomEdgeRect = bounds
        bottomEdgeRect.size.height = 1.0
        bottomEdgeRect.fill(using: .sourceOver)
        
        var topEdgeRect = bottomEdgeRect
        topEdgeRect.origin.y = NSMaxY(bounds) - 1.0
        topEdgeRect.fill(using: .sourceOver)
    }
    
}
