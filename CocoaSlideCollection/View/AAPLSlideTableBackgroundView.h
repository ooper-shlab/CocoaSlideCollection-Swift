/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "SlideTableBackgroundView" class declaration.
*/

#import <Cocoa/Cocoa.h>

// A simple background view for our NSCollectionView, that draws a subtle radial gradient using NSGradient, or an NSImage scaled to cover the entire background.
@interface AAPLSlideTableBackgroundView : NSView
{
    NSGradient *gradient;
    NSImage *image;
}
@property(strong) NSImage *image;
@end
