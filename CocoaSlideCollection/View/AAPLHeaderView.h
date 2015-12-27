/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "HeaderView" class declaration.
*/

#import <Cocoa/Cocoa.h>
#import <AppKit/NSCollectionView.h>

@interface AAPLHeaderView : NSView <NSCollectionViewElement>

@property(readonly) NSTextField *titleTextField;

@end
