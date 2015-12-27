/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "SlideCarrierView" class implementation.
*/

#import "AAPLSlideCarrierView.h"
#import "AAPLSlideBorderView.h"
#import "AAPLSlideImageView.h"
#import <QuartzCore/QuartzCore.h>

@implementation AAPLSlideCarrierView

#pragma mark Animation

// Override the default @"frameOrigin" animation for SlideCarrierViews, to use an "EaseInEaseOut" timing curve.
+ (id)defaultAnimationForKey:(NSString *)key {
    static CABasicAnimation *basicAnimation = nil;
    if ([key isEqual:@"frameOrigin"]) {
        if (basicAnimation == nil) {
            basicAnimation = [[CABasicAnimation alloc] init];
            [basicAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        }
        return basicAnimation;
    } else {
        return [super defaultAnimationForKey:key];
    }
}


#pragma mark Initializing

- (nonnull instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        highlightState = NSCollectionViewItemHighlightNone;
    }
    return self;
}


#pragma mark Property Accessors

- (NSCollectionViewItemHighlightState)highlightState {
    return highlightState;
}

- (void)setHighlightState:(NSCollectionViewItemHighlightState)newHighlightState {
    if (highlightState != newHighlightState) {
        highlightState = newHighlightState;

        // Cause our -updateLayer method to be invoked, so we can update our appearance to reflect the new state.
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)isSelected {
    return selected;
}

- (void)setSelected:(BOOL)flag {
    if (selected != flag) {
        selected = flag;

        // Cause our -updateLayer method to be invoked, so we can update our appearance to reflect the new state.
        [self setNeedsDisplay:YES];
    }
}


#pragma mark Visual State

// A AAPLSlideCarrierView wants to receive -updateLayer so it can set its backing layer's contents property, instead of being sent -drawRect: to draw its content procedurally.
- (BOOL)wantsUpdateLayer {
    return YES;
}

// Returns the slide's AAPLSlideBorderView (if it currently has one).
- (AAPLSlideBorderView *)borderView {
    for (NSView *subview in self.subviews) {
        if ([subview isKindOfClass:[AAPLSlideBorderView class]]) {
            return (AAPLSlideBorderView *)subview;
        }
    }
    return nil;
}

// Invoked from our -updateLayer override.  Adds a AAPLSlideBorderView subview with appropriate properties (or removes an existing AAPLSlideBorderView), as appropriate to visually indicate the slide's "highlightState" and whether the slide is "selected".
- (void)updateBorderView {
    NSColor *borderColor = nil;
    if (highlightState == NSCollectionViewItemHighlightForSelection) {

        // Item is a candidate to become selected: Show an orange border around it.
        borderColor = [NSColor orangeColor];

    } else if (highlightState == NSCollectionViewItemHighlightAsDropTarget) {

        // Item is a candidate to receive dropped items: Show a red border around it.
        borderColor = [NSColor redColor];

    } else if (selected && highlightState != NSCollectionViewItemHighlightForDeselection) {

        // Item is selected, and is not indicated for proposed deselection: Show an Aqua border around it.
        borderColor = [NSColor colorWithCalibratedRed:0.0 green:0.5 blue:1.0 alpha:1.0]; // Aqua

    } else {
        // Item is either not selected, or is selected but not highlighted for deselection: Sbhow no border around it.
        borderColor = nil;
    }

    // Add/update or remove a AAPLSlideBorderView subview, according to whether borderColor != nil.
    AAPLSlideBorderView *borderView = self.borderView;
    if (borderColor) {
        if (borderView == nil) {
            NSRect bounds = self.bounds;
            NSRect shapeBox = NSInsetRect(bounds, (SLIDE_SHADOW_MARGIN - 0.5 * SLIDE_BORDER_WIDTH), (SLIDE_SHADOW_MARGIN - 0.5 * SLIDE_BORDER_WIDTH));
            borderView = [[AAPLSlideBorderView alloc] initWithFrame:shapeBox];
            [self addSubview:borderView];
        }
        borderView.borderColor = borderColor;
    } else {
        [borderView removeFromSuperview];
    }
}

- (void)updateLayer {
    // Provide the SlideCarrierView's backing layer's contents directly, instead of via -drawRect:.
    self.layer.contents = [NSImage imageNamed:@"SlideCarrier"];
    
    // Use this as an opportunity to update our AAPLSlideBorderView.
    [self updateBorderView];
}

// Used by our -hitTest: method, below.  Returns the slide's rounded-rectangle hit-testing shape, expressed as an NSBezierPath.
- (NSBezierPath *)slideShape {
    NSRect bounds = self.bounds;
    NSRect shapeBox = NSInsetRect(bounds, SLIDE_SHADOW_MARGIN, SLIDE_SHADOW_MARGIN);
    return [NSBezierPath bezierPathWithRoundedRect:shapeBox xRadius:SLIDE_CORNER_RADIUS yRadius:SLIDE_CORNER_RADIUS];
}

- (NSView *)hitTest:(NSPoint)aPoint {
    // Hit-test against the slide's rounded-rect shape.
    NSPoint pointInSelf = [self convertPoint:aPoint fromView:self.superview];
    NSRect bounds = self.bounds;
    if (!NSPointInRect(pointInSelf, bounds)) {
        return NO;
    } else if (![self.slideShape containsPoint:pointInSelf]) {
        return NO;
    } else {
        return [super hitTest:aPoint];
    }
}

@end
