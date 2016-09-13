//
//  AAPLSlideImageView.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/26.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample‚Äôs licensing information

    Abstract:
    This is the "SlideImageView" class declaration.
*/

import Cocoa

// A AAPLSlideImageView is a slightly customized NSImageView, that composites semitransparent bands over areas the slide's image doesn't cover, for a more slide-like appearance.
@objc(AAPLSlideImageView)
class AAPLSlideImageView: NSImageView {
    
    // Fill in semitransparent gray bands in any areas that the image doesn't cover, to give a more slide-like appearance.
    override func draw(_ rect: NSRect) {
        if let image = self.image , self.imageScaling == .scaleProportionallyDown {
            let imageSize = image.size
            let viewSize = self.bounds.size
            if imageSize.height > 0.0 && viewSize.height > 0.0 {
                let imageAspectRatio = imageSize.width / imageSize.height
                let viewAspectRatio = viewSize.width / viewSize.height
                NSColor(calibratedWhite: 0.0, alpha: 0.2).set()
                if imageAspectRatio > viewAspectRatio {
                    // Fill in bands at top and bottom.
                    let thumbnailHeight = viewSize.width / imageAspectRatio
                    let bandHeight = 0.5 * (viewSize.height - thumbnailHeight)
                    NSRectFillUsingOperation(NSMakeRect(0, 0, viewSize.width, bandHeight), .sourceOver)
                    NSRectFillUsingOperation(NSMakeRect(0, viewSize.height - bandHeight, viewSize.width, bandHeight), .sourceOver)
                } else if imageAspectRatio < viewAspectRatio {
                    // Fill in bands at left and right.
                    let thumbnailWidth = viewSize.height * imageAspectRatio
                    let bandWidth = 0.5 * (viewSize.width - thumbnailWidth)
                    NSRectFillUsingOperation(NSMakeRect(0, 0, bandWidth, viewSize.height), .sourceOver)
                    NSRectFillUsingOperation(NSMakeRect(viewSize.width - bandWidth, 0, bandWidth, viewSize.height), .sourceOver)
                }
            }
        }
        
        // Now let NSImageView do its drawing.
        super.draw(rect)
    }
    
}
