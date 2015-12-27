/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "LoopLayout" class declaration.
*/

#import "AAPLSlideLayout.h"

// Positions items in an "infinity"-shaped loop, within the available area.
@interface AAPLLoopLayout : AAPLSlideLayout
{
    NSPoint loopCenter;
    NSSize loopSize;
}
@end
