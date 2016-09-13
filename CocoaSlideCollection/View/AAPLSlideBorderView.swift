//
//  AAPLSlideBorderView.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/26.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    This is the "SlideBorderView" class declaration.
*/

import Cocoa

// Added as a subview of a AAPLSlideCarrierView, when we want to frame the slide's shape with a stroked outline to indicate selection or highlighting.
@objc(AAPLSlideBorderView)
class AAPLSlideBorderView: NSView {
    private var _borderColor: NSColor?
    
    //MARK: Property Accessors
    
    var borderColor: NSColor? {
        get {
            return _borderColor
        }
        
        set(newBorderColor) {
            if _borderColor != newBorderColor {
                _borderColor = newBorderColor?.copy() as! NSColor?
                self.needsDisplay = true
            }
        }
    }
    
    //MARK: Visual State
    
    // A AAPLSlideCarrierView wants to receive -updateLayer so it can set its backing layer's contents property, instead of being sent -drawRect: to draw its content procedurally.
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override func updateLayer() {
        if let layer = self.layer {
            layer.borderColor = borderColor?.cgColor
            layer.borderWidth = (borderColor != nil ? SLIDE_BORDER_WIDTH : 0.0)
            layer.cornerRadius = SLIDE_CORNER_RADIUS
        }
    }
    
}
