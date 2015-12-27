/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "ScatterLayout" class declaration.
*/

#import "AAPLSlideLayout.h"

// Positions items randomly, within the available area.
@interface AAPLScatterLayout : AAPLSlideLayout
{
    NSMutableDictionary *cachedItemFrames;
}
@end
