//
//  AAPLSlideCarrierView.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/26.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample‚Äôs licensing information

    Abstract:
    This is the "SlideCarrierView" class declaration.
*/

import Cocoa

let SLIDE_WIDTH: CGFloat = 140.0     // width  of the SlideCarrier image (which includes shadow margins) in points, and thus the width  that we give to a Slide's root view
let SLIDE_HEIGHT: CGFloat = 140.0     // height of the SlideCarrier image (which includes shadow margins) in points, and thus the height that we give to a Slide's root view

let SLIDE_SHADOW_MARGIN: CGFloat = 10.0     // margin on each side between the actual slide shape edge and the edge of the SlideCarrier image
let SLIDE_CORNER_RADIUS: CGFloat = 8.0     // corner radius of the slide shape in points
let SLIDE_BORDER_WIDTH: CGFloat = 4.0     // thickness of border when shown, in points

// A AAPLSlideCarrierView serves as the container view for each AAPLSlide item.  It displays a "SlideCarrier" slide shape image with built-in shadow, customizes hit-testing to account for the slide shape's rounded corners, and implements visual indication of item selection and highlighting state.
@objc(AAPLSlideCarrierView)
class AAPLSlideCarrierView: NSView {
    private var _highlightState: NSCollectionViewItemHighlightState = .None
    private var _selected: Bool = false
    
    //MARK: Animation
    
    // Override the default @"frameOrigin" animation for SlideCarrierViews, to use an "EaseInEaseOut" timing curve.
    override class func defaultAnimationForKey(key: String) -> AnyObject? {
        struct My {
            static var basicAnimation: CABasicAnimation? = nil
        }
        if key == "frameOrigin" {
            if My.basicAnimation == nil {
                My.basicAnimation = CABasicAnimation()
                My.basicAnimation!.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            }
            return My.basicAnimation!
        } else {
            return super.defaultAnimationForKey(key)
        }
    }
    
    
    //MARK: Initializing
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _highlightState = .None
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: Property Accessors
    
    // To leave the specifics of highlighted and selected appearance to the SlideCarrierView's implementation, we mirror NSCollectionViewItem's "highlightState" and "selected" properties to it.
    var highlightState: NSCollectionViewItemHighlightState {
        get {
            return _highlightState
        }
        
        set(newHighlightState) {
            if _highlightState != newHighlightState {
                _highlightState = newHighlightState
                
                // Cause our -updateLayer method to be invoked, so we can update our appearance to reflect the new state.
                self.needsDisplay = true
            }
        }
    }
    
    var selected: Bool {
        get {
            return _selected
        }
        
        set(flag) {
            if _selected != flag {
                _selected = flag
                
                // Cause our -updateLayer method to be invoked, so we can update our appearance to reflect the new state.
                self.needsDisplay = true
            }
        }
    }
    
    
    //MARK: Visual State
    
    // A AAPLSlideCarrierView wants to receive -updateLayer so it can set its backing layer's contents property, instead of being sent -drawRect: to draw its content procedurally.
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    // Returns the slide's AAPLSlideBorderView (if it currently has one).
    private var borderView: AAPLSlideBorderView? {
        
        for subview in self.subviews {
            if let borderView = subview as? AAPLSlideBorderView {
                return borderView
            }
        }
        return nil
    }
    
    // Invoked from our -updateLayer override.  Adds a AAPLSlideBorderView subview with appropriate properties (or removes an existing AAPLSlideBorderView), as appropriate to visually indicate the slide's "highlightState" and whether the slide is "selected".
    private func updateBorderView() {
        var borderColor: NSColor? = nil
        if highlightState == .ForSelection {
            
            // Item is a candidate to become selected: Show an orange border around it.
            borderColor = NSColor.orangeColor()
            
        } else if highlightState == .AsDropTarget {
            
            // Item is a candidate to receive dropped items: Show a red border around it.
            borderColor = NSColor.redColor()
            
        } else if selected && highlightState != .ForDeselection {
            
            // Item is selected, and is not indicated for proposed deselection: Show an Aqua border around it.
            borderColor = NSColor(calibratedRed: 0.0, green: 0.5, blue: 1.0, alpha: 1.0) // Aqua
            
        } else {
            // Item is either not selected, or is selected but not highlighted for deselection: Sbhow no border around it.
            borderColor = nil
        }
        
        // Add/update or remove a AAPLSlideBorderView subview, according to whether borderColor != nil.
        var borderView = self.borderView
        if let borderColor = borderColor {
            if borderView == nil {
                let bounds = self.bounds
                let shapeBox = NSInsetRect(bounds, (SLIDE_SHADOW_MARGIN - 0.5 * SLIDE_BORDER_WIDTH), (SLIDE_SHADOW_MARGIN - 0.5 * SLIDE_BORDER_WIDTH))
                borderView = AAPLSlideBorderView(frame: shapeBox)
                self.addSubview(borderView!)
            }
            borderView!.borderColor = borderColor
        } else {
            borderView?.removeFromSuperview()
        }
    }
    
    override func updateLayer() {
        // Provide the SlideCarrierView's backing layer's contents directly, instead of via -drawRect:.
        self.layer?.contents = NSImage(named: "SlideCarrier")
        
        // Use this as an opportunity to update our AAPLSlideBorderView.
        self.updateBorderView()
    }
    
    // Used by our -hitTest: method, below.  Returns the slide's rounded-rectangle hit-testing shape, expressed as an NSBezierPath.
    private var slideShape: NSBezierPath {
        let bounds = self.bounds
        let shapeBox = NSInsetRect(bounds, SLIDE_SHADOW_MARGIN, SLIDE_SHADOW_MARGIN)
        return NSBezierPath(roundedRect: shapeBox, xRadius: SLIDE_CORNER_RADIUS, yRadius: SLIDE_CORNER_RADIUS)
    }
    
    override func hitTest(aPoint: NSPoint) -> NSView? {
        // Hit-test against the slide's rounded-rect shape.
        let pointInSelf = self.convertPoint(aPoint, fromView: self.superview)
        let bounds = self.bounds
        if !NSPointInRect(pointInSelf, bounds) {
            return nil
        } else if !self.slideShape.containsPoint(pointInSelf) {
            return nil
        } else {
            return super.hitTest(aPoint)
        }
    }
    
}