/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "SlideBorderView" class declaration.
*/

#import <Cocoa/Cocoa.h>

// Added as a subview of a AAPLSlideCarrierView, when we want to frame the slide's shape with a stroked outline to indicate selection or highlighting.
@interface AAPLSlideBorderView : NSView
{
    NSColor *borderColor;
}

@property(copy) NSColor *borderColor;

@end
