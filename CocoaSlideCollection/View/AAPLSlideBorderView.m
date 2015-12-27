/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "SlideBorderView" class implementation.
*/

#import "AAPLSlideBorderView.h"
#import "AAPLSlideCarrierView.h"

@implementation AAPLSlideBorderView

#pragma mark Property Accessors

- (NSColor *)borderColor {
    return borderColor;
}

- (void)setBorderColor:(NSColor *)newBorderColor {
    if (borderColor != newBorderColor) {
        borderColor = [newBorderColor copy];
        [self setNeedsDisplay:YES];
    }
}

#pragma mark Visual State

// A AAPLSlideCarrierView wants to receive -updateLayer so it can set its backing layer's contents property, instead of being sent -drawRect: to draw its content procedurally.
- (BOOL)wantsUpdateLayer {
    return YES;
}

- (void)updateLayer {
    CALayer *layer = self.layer;
    layer.borderColor = borderColor.CGColor;
    layer.borderWidth = (borderColor ? SLIDE_BORDER_WIDTH : 0.0);
    layer.cornerRadius = SLIDE_CORNER_RADIUS;
}

@end
