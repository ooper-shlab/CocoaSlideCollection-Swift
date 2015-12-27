/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "ScatterLayout" class implementation.
*/

#import "AAPLScatterLayout.h"

@implementation AAPLScatterLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        cachedItemFrames = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSCollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSValue *frameValue = [cachedItemFrames objectForKey:indexPath];
    if (frameValue == nil) {
        NSPoint p;
        p.x = box.origin.x + drand48() * (box.size.width - itemSize.width);
        p.y = box.origin.y + drand48() * (box.size.height - itemSize.height);
        frameValue = [NSValue valueWithRect:NSMakeRect(p.x, p.y, itemSize.width, itemSize.height)];
        [cachedItemFrames setObject:frameValue forKey:indexPath];
    }
    
    NSCollectionViewLayoutAttributes *attributes = [[[self class] layoutAttributesClass] layoutAttributesForItemWithIndexPath:indexPath];
    [attributes setFrame:[frameValue rectValue]];
    [attributes setZIndex:[indexPath item]];
    return attributes;
}

@end
