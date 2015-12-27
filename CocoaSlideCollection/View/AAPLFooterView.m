/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "SlideCarrierView" class implementation.
*/

#import "AAPLFooterView.h"

@implementation AAPLFooterView

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor colorWithCalibratedWhite:0.85 alpha:0.8] set];
    NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
}

@end
