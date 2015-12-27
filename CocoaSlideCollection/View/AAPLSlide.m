/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "Slide" NSCollectionViewItem subclass implementation.
*/

#import "AAPLSlide.h"
#import "AAPLImageFile.h"
#import "AAPLSlideCarrierView.h"
#import "AAPLSlideLayout.h"
#import "AAPLSlideTableBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

@implementation AAPLSlide

#pragma mark Selection and Highlighting Support

- (void)setHighlightState:(NSCollectionViewItemHighlightState)newHighlightState {
    [super setHighlightState:newHighlightState];
    
    // Relay the newHighlightState to our AAPLSlideCarrierView.
    [(AAPLSlideCarrierView *)[self view] setHighlightState:newHighlightState];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];

    // Relay the new "selected" state to our AAPLSlideCarrierView.
    [(AAPLSlideCarrierView *)[self view] setSelected:selected];
}


#pragma mark Represented Object

- (AAPLImageFile *)imageFile {
    return (AAPLImageFile *)(self.representedObject);
}

// We set a Slide's representedObject to point to the AAPLImageFile it stands for.  If you aren't using Bindings to provide the desired content for your item's views, an override of -setRepresentedObject: is a handy place to manually set such content when the model object (AAPLImageFile) is first associated with the item (AAPLSlide).  (Another good place to do that is in the -collectionView:willDisplayItem:forRepresentedObjectAtIndexPath: delegate method, depending how your like to factor your code.)  Our project uses Bindings to populate a Slide's imageView and NSTextFields, but we do use -setRepresentedObject: as an opportunity to request asynchronous loading of the ImageFile's previewImage.  When the previewImage has finished loading on a background thread, the AAPLImageFile will get a -setPreviewImage: message, scheduled for delivery on the main thread.  The Slide's imageView, whose content is bound to our representedObject's previewImage property, will then automatically show the loaded preview image.
- (void)setRepresentedObject:(id)newRepresentedObject {
    [super setRepresentedObject:newRepresentedObject];

    // Request loading of the ImageFile's previewImage.
    [self.imageFile requestPreviewImage];
}


#pragma mark Event Handling

// When a slide is double-clicked, open the image file.
- (void)mouseDown:(NSEvent *)theEvent {
    if ([theEvent clickCount] == 2) {
        [self openImageFile:self];
    } else {
        [super mouseDown:theEvent];
    }
}


#pragma mark Actions

// Open the image file, using the default app for files of its type.
- (IBAction)openImageFile:(id)sender {
    NSURL *url = self.imageFile.url;
    if (url) {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (AAPLSlideTableBackgroundView *)slideTableBackgroundView {
    // Find our AAPLSlideTableBackgroundView via NSCollectionViewItem's "collectionView" property.
    NSView *backgroundView = self.collectionView.backgroundView;
    return [backgroundView isKindOfClass:[AAPLSlideTableBackgroundView class]] ? (AAPLSlideTableBackgroundView *)backgroundView : nil;
}

// Set the image as the CollectionView's background (using the "backgroundView" property).
- (IBAction)setCollectionViewBackground:(id)sender {
    self.slideTableBackgroundView.image = [[NSImage alloc] initByReferencingURL:self.imageFile.url];
}

// Clear the CollectionView's background back to its default appearance.
- (IBAction)clearCollectionViewBackground:(id)sender {
    self.slideTableBackgroundView.image = nil;
}


#pragma mark Drag and Drop Support

// Override NSCollectionViewItem's -draggingImageComponents getter to return a snapshot of the entire slide as its dragging image.
- (NSArray *)draggingImageComponents {
    
    // Image itemRootView.
    NSView *itemRootView = self.view;
    NSRect itemBounds = itemRootView.bounds;
    NSBitmapImageRep *bitmap = [itemRootView bitmapImageRepForCachingDisplayInRect:itemBounds];
    unsigned char *bitmapData = bitmap.bitmapData;
    if (bitmapData) {
        bzero(bitmapData, bitmap.bytesPerRow * bitmap.pixelsHigh);
    }
    
    /*
        -cacheDisplayInRect:toBitmapImageRep: won't capture the "SlideCarrier"
        image, since it's rendered via the layer contents property.  Work around
        that by drawing the image into the bitmap ourselves, using a bitmap
        graphics context.
    */
    // Work around SlideCarrierView layer contents not being rendered to bitmap.
    NSImage *slideCarrierImage = [NSImage imageNamed:@"SlideCarrier"];
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *oldContext = [NSGraphicsContext currentContext];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
    [slideCarrierImage drawInRect:itemBounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [NSGraphicsContext setCurrentContext:oldContext];
    [NSGraphicsContext restoreGraphicsState];
    
    /*
        Invoke -cacheDisplayInRect:toBitmapImageRep: to render the rest of the
        itemRootView subtree into the bitmap.
    */
    [itemRootView cacheDisplayInRect:itemBounds toBitmapImageRep:bitmap];
    NSImage *image = [[NSImage alloc] initWithSize:[bitmap size]];
    [image addRepresentation:bitmap];
    
    NSDraggingImageComponent *component = [[NSDraggingImageComponent alloc] initWithKey:NSDraggingImageComponentIconKey];
    component.frame = itemBounds;
    component.contents = image;

    return [NSArray arrayWithObject:component];
}

@end
