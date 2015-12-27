/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "SlideCarrierView" class declaration.
*/

#import <Cocoa/Cocoa.h>

#define SLIDE_WIDTH           140.0     // width  of the SlideCarrier image (which includes shadow margins) in points, and thus the width  that we give to a Slide's root view
#define SLIDE_HEIGHT          140.0     // height of the SlideCarrier image (which includes shadow margins) in points, and thus the height that we give to a Slide's root view

#define SLIDE_SHADOW_MARGIN    10.0     // margin on each side between the actual slide shape edge and the edge of the SlideCarrier image
#define SLIDE_CORNER_RADIUS     8.0     // corner radius of the slide shape in points
#define SLIDE_BORDER_WIDTH      4.0     // thickness of border when shown, in points

// A AAPLSlideCarrierView serves as the container view for each AAPLSlide item.  It displays a "SlideCarrier" slide shape image with built-in shadow, customizes hit-testing to account for the slide shape's rounded corners, and implements visual indication of item selection and highlighting state.
@interface AAPLSlideCarrierView : NSView
{
    NSCollectionViewItemHighlightState highlightState;
    BOOL selected;
}

// To leave the specifics of highlighted and selected appearance to the SlideCarrierView's implementation, we mirror NSCollectionViewItem's "highlightState" and "selected" properties to it.
@property NSCollectionViewItemHighlightState highlightState;
@property (getter=isSelected) BOOL selected;

@end
