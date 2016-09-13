//
//  AAPLSlideTableBackgroundView.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/26.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    This is the "SlideTableBackgroundView" class declaration.
*/

import Cocoa

// A simple background view for our NSCollectionView, that draws a subtle radial gradient using NSGradient, or an NSImage scaled to cover the entire background.
@objc(AAPLSlideTableBackgroundView)
class AAPLSlideTableBackgroundView: NSView {
    private var gradient: NSGradient
    private var _image: NSImage?
    
    override init(frame frameRect: NSRect) {
        let centerColor = NSColor(calibratedRed: 0.94, green: 0.99, blue: 0.98, alpha: 1.0)
        let outerColor = NSColor(calibratedRed: 0.91, green: 1.0, blue: 0.98, alpha: 1.0)
        gradient = NSGradient(starting: centerColor, ending: outerColor)!
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isOpaque: Bool {
        return true
    }
    
    var image: NSImage? {
        get {
            return _image
        }
        
        set(newImage) {
            if _image !== newImage {
                _image = newImage
                self.needsDisplay = true
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let image = image {
            // Draw an image, scaled proportionally to fill the view's entire bounds.
            let imageSize = image.size
            let bounds = self.bounds
            let scaleToFillWidth = bounds.size.width / imageSize.width
            let scaleToFillHeight = bounds.size.height / imageSize.height
            
            // Choose the greater of the scale factor required to fill the view's width, and the scale factor required to fill the view's height, and compute the destination rect accordingly.
            var destRect: NSRect
            if scaleToFillWidth > scaleToFillHeight {
                destRect = NSMakeRect(bounds.origin.x, NSMidY(bounds) - 0.5 * scaleToFillWidth * imageSize.height, bounds.size.width, scaleToFillWidth * imageSize.height)
            } else {
                destRect = NSMakeRect(NSMidX(bounds) - 0.5 * scaleToFillHeight * imageSize.width, bounds.origin.y, scaleToFillHeight * imageSize.width, bounds.size.height)
            }
            image.draw(in: destRect, from: NSMakeRect(0, 0, imageSize.width, imageSize.height), operation: .sourceOver, fraction: 1.0)
        } else {
            // Draw a slight radial gradient.
            gradient.draw(in: self.bounds, relativeCenterPosition: NSZeroPoint)
        }
    }
    
}
