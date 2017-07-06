//
//  AAPLSlide.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/26.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample‚Äôs licensing information

    Abstract:
    This is the "Slide" NSCollectionViewItem subclass declaration.
*/

import Cocoa

/*
An NSCollectionViewItem that visually represents an AAPLImageFile in an
NSCollectionView.  A Slide's "representedObject" property points to its
AAPLImageFile.
*/
@objc(AAPLSlide)
class AAPLSlide: NSCollectionViewItem {
    
    //MARK: Outlets
    
    // From NSCollectionViewItem, we also inherit an "imageView" outlet (which we wire up to the AAPLSlideImageView that shows our ImageFile's previewImage) and a "textField" outlet (which we wire up to the NSTextField that shows the ImageFile's filenameWithoutExtension).
    
    // An NSTextField that shows a description of the ImageFile's kind (e.g. "JPEG image", "PNG image")
    @IBOutlet weak var kindTextField: NSTextField!
    
    // An NSTextField that shows the pixel dimensions of the ImageFile's main image (e.g. "5120 x 2880")
    @IBOutlet weak var dimensionsTextField: NSTextField!
    
    
    //MARK: Selection and Highlighting Support
    
    override var highlightState: NSCollectionViewItemHighlightState {
        get {
            return super.highlightState
        }
        set(newHighlightState) {
            super.highlightState = newHighlightState
            
            // Relay the newHighlightState to our AAPLSlideCarrierView.
            (self.view as! AAPLSlideCarrierView).highlightState = newHighlightState
        }
    }
    
    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            super.isSelected = newValue
            
            // Relay the new "selected" state to our AAPLSlideCarrierView.
            (self.view as! AAPLSlideCarrierView).selected = newValue
        }
    }
    
    
    //MARK: Represented Object
    
    var imageFile: AAPLImageFile? {
        return self.representedObject as! AAPLImageFile?
    }
    
    // We set a Slide's representedObject to point to the AAPLImageFile it stands for.  If you aren't using Bindings to provide the desired content for your item's views, an override of -setRepresentedObject: is a handy place to manually set such content when the model object (AAPLImageFile) is first associated with the item (AAPLSlide).  (Another good place to do that is in the -collectionView:willDisplayItem:forRepresentedObjectAtIndexPath: delegate method, depending how your like to factor your code.)  Our project uses Bindings to populate a Slide's imageView and NSTextFields, but we do use -setRepresentedObject: as an opportunity to request asynchronous loading of the ImageFile's previewImage.  When the previewImage has finished loading on a background thread, the AAPLImageFile will get a -setPreviewImage: message, scheduled for delivery on the main thread.  The Slide's imageView, whose content is bound to our representedObject's previewImage property, will then automatically show the loaded preview image.
    override var representedObject: Any? {
        get {
            return super.representedObject as AnyObject?
        }
        set(newRepresentedObject) {
            super.representedObject = newRepresentedObject
            
            // Request loading of the ImageFile's previewImage.
            self.imageFile?.requestPreviewImage()
        }
    }
    
    
    //MARK: Event Handling
    
    // When a slide is double-clicked, open the image file.
    override func mouseDown(with theEvent: NSEvent) {
        if theEvent.clickCount == 2 {
            self.openImageFile(self)
        } else {
            super.mouseDown(with: theEvent)
        }
    }
    
    
    //MARK: Actions
    
    // Open the image file, using the default app for files of its type.
    @IBAction func openImageFile(_: AnyObject) {
        if let url = self.imageFile?.url {
            NSWorkspace.shared().open(url as URL)
        }
    }
    
    private var slideTableBackgroundView: AAPLSlideTableBackgroundView? {
        // Find our AAPLSlideTableBackgroundView via NSCollectionViewItem's "collectionView" property.
        let backgroundView = self.collectionView.backgroundView
        return backgroundView is AAPLSlideTableBackgroundView ? (backgroundView as! AAPLSlideTableBackgroundView) : nil
    }
    
    // Set the image as the CollectionView's background (using the "backgroundView" property).
    @IBAction func setCollectionViewBackground(_: AnyObject) {
        self.slideTableBackgroundView?.image = NSImage(byReferencing: self.imageFile!.url)
    }
    
    // Clear the CollectionView's background back to its default appearance.
    @IBAction func clearCollectionViewBackground(_: AnyObject) {
        self.slideTableBackgroundView?.image = nil
    }
    
    
    //MARK: Drag and Drop Support
    
    // Override NSCollectionViewItem's -draggingImageComponents getter to return a snapshot of the entire slide as its dragging image.
    override var draggingImageComponents: [NSDraggingImageComponent] {
        
        // Image itemRootView.
        let itemRootView = self.view
        let itemBounds = itemRootView.bounds
        let bitmap = itemRootView.bitmapImageRepForCachingDisplay(in: itemBounds)!
        let bitmapData = bitmap.bitmapData
        if bitmapData != nil {
            bzero(bitmapData, bitmap.bytesPerRow * bitmap.pixelsHigh)
        }
        
        /*
        -cacheDisplayInRect:toBitmapImageRep: won't capture the "SlideCarrier"
        image, since it's rendered via the layer contents property.  Work around
        that by drawing the image into the bitmap ourselves, using a bitmap
        graphics context.
        */
        // Work around SlideCarrierView layer contents not being rendered to bitmap.
        let slideCarrierImage = NSImage(named: "SlideCarrier")
        NSGraphicsContext.saveGraphicsState()
        let oldContext = NSGraphicsContext.current()
        NSGraphicsContext.setCurrent(NSGraphicsContext(bitmapImageRep: bitmap))
        slideCarrierImage?.draw(in: itemBounds, from: NSZeroRect, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.setCurrent(oldContext)
        NSGraphicsContext.restoreGraphicsState()
        
        /*
        Invoke -cacheDisplayInRect:toBitmapImageRep: to render the rest of the
        itemRootView subtree into the bitmap.
        */
        itemRootView.cacheDisplay(in: itemBounds, to: bitmap)
        let image = NSImage(size: bitmap.size)
        image.addRepresentation(bitmap)
        
        let component = NSDraggingImageComponent(key: NSDraggingImageComponentIconKey)
        component.frame = itemBounds
        component.contents = image
        
        return [component]
    }
    
}
