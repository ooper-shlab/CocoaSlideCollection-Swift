/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "CircularLayout" class declaration.
*/

#import "AAPLSlideLayout.h"

// Positions items in a circle, within the available area.
@interface AAPLCircularLayout : AAPLSlideLayout
{
    NSPoint circleCenter;
    CGFloat circleRadius;
}
@end
