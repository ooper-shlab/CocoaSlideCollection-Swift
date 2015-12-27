/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "HeaderView" class implementation.
*/

#import "AAPLHeaderView.h"

@implementation AAPLHeaderView

// Returns the HeaderView's title NSTextField (if it currently has one).
- (NSTextField *)titleTextField {
    for (NSView *view in self.subviews) {
        if ([view isKindOfClass:[NSTextField class]]) {
            return (NSTextField *)view;
        }
    }
    return nil;
}

// Draws the HeaderView's background: semitransparent white fill, with highlight and shadow lines at top and bottom.
- (void)drawRect:(NSRect)dirtyRect {
    // Fill with semitransparent white.
    [[NSColor colorWithCalibratedWhite:0.95 alpha:0.8] set];
    NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);

    // Fill bottom and top edges with semitransparent gray.
    [[NSColor colorWithCalibratedWhite:0.75 alpha:0.8] set];
    NSRect bounds = self.bounds;
    NSRect bottomEdgeRect = bounds;
    bottomEdgeRect.size.height = 1.0;
    NSRectFillUsingOperation(bottomEdgeRect, NSCompositeSourceOver);
    
    NSRect topEdgeRect = bottomEdgeRect;
    topEdgeRect.origin.y = NSMaxY(bounds) - 1.0;
    NSRectFillUsingOperation(topEdgeRect, NSCompositeSourceOver);
}

@end
