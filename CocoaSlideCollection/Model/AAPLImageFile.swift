//
//  AAPLImageFile.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/23.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample‚Äôs licensing information

    Abstract:
    This is the "ImageFile" class declaration.
*/

import Cocoa

// This is our Model representation of an image file.  It provides access to the file's properties and its contained image, including pixel dimensions and a thumbnail preview.
@objc(AAPLImageFile)
class AAPLImageFile: NSObject {
    private var imageSource: CGImageSource?           // NULL until metadata is loaded
    private var imageProperties: [AnyHashable: Any]?          // nil until metadata is loaded
    
    
    //MARK: File Properties
    
    var url: URL
    @objc dynamic var fileType: String?
    var fileSize: UInt64 = 0
    var dateLastUpdated: Date?
    var tagNames: [String] = []
    
    
    //MARK: Image Properties
    
    @objc dynamic var previewImage: NSImage?
    
    
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if key == "localizedTypeDescription" {
            return ["fileType"]
        } else {
            return super.keyPathsForValuesAffectingValue(forKey: key)
        }
    }
    
    private static var previewLoadingOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "AAPLImageFile Preview Loading Queue"
        return queue
    }()
    
    private static let demoTagNamesDictionary: [String: [String]] = [
        "Abstract" : ["Texture"],
        "Antelope Canyon" : ["Landscape", "Texture"],
        "Bahamas Aerial" : ["Landscape", "Texture"],
        "Beach" : ["Landscape", "Water"],
        "Blue Pond" : ["Flora", "Landscape", "Snow", "Water"],
        "Bristle Grass" : ["Flora", "Landscape"],
        "Brushes" : ["Texture"],
        "Circles" : ["Texture"],
        "Death Valley" : ["Landscape"],
        "Desert" : ["Landscape", "Texture"],
        "Ducks on a Misty Pond" : ["Fauna", "Landscape", "Water"],
        "Eagle & Waterfall" : ["Fauna", "Landscape", "Water"],
        "Earth and Moon" : ["Space"],
        "Earth Horizon" : ["Space"],
        "Elephant" : ["Fauna", "Landscape"],
        "Flamingos" : ["Fauna", "Landscape", "Water"],
        "Floating Ice" : ["Landscape", "Snow", "Water"]
    ]
    
    class func demoTagNamesForImageFileURL(_ url: URL) -> [String]? {
        let filenameWithoutExtension = url.deletingPathExtension().lastPathComponent
        return self.demoTagNamesDictionary[filenameWithoutExtension]
    }
    
    init(URL newURL: URL) {
        self.url = newURL
        
        // Get properties that we can obtain from the URL.
        do {
            let resource = try newURL.resourceValues(forKeys: [.typeIdentifierKey, .fileSizeKey, .contentModificationDateKey, .tagNamesKey])
            self.fileType = resource.typeIdentifier!
            self.fileSize = UInt64(resource.fileSize!)
            self.dateLastUpdated = resource.contentModificationDate!
            self.tagNames = resource.tagNames ?? []
        } catch _ {}
        super.init()
        if self.tagNames.isEmpty {
            // For Demo purposes, since the image files in "/Library/Desktop Pictures" don't have tags assigned to them, hardwire tagNames of our own.
            self.tagNames = type(of: self).demoTagNamesForImageFileURL(self.url) ?? []
        }
    }
    
    
    //MARK: File Properties
    
    var filename: String {
        return self.url.lastPathComponent
    }
    
    var filenameWithoutExtension: String? {
        return self.url.deletingPathExtension().lastPathComponent
    }
    
    var localizedTypeDescription: String? {
        if let type = self.fileType {
            return NSWorkspace.shared().localizedDescription(forType: type)
        } else {
            return nil
        }
    }
    
    var dimensionsDescription: String {
        return "\(self.pixelsWide) x \(self.pixelsHigh)"
    }
    
    
    //MARK: Image Properties
    
    var pixelsWide: Int {
        if imageProperties == nil {
            self.loadMetadata()
        }
        return imageProperties![kCGImagePropertyPixelWidth as AnyHashable] as! Int
    }
    
    var pixelsHigh: Int {
        if imageProperties == nil {
            self.loadMetadata()
        }
        return imageProperties![kCGImagePropertyPixelHeight as AnyHashable] as! Int
    }
    
    
    //MARK: Loading
    
    /* Many kinds of image files contain prerendered thumbnail images that can be quickly loaded without having to decode the entire contents of the image file and reconstruct the full-size image.  The ImageIO framework's CGImageSource API provides a means to do this, using the CGImageSourceCreateThumbnailAtIndex() function.  For more information on CGImageSource objects and their capabilities, see the CGImageSource reference on the Apple Developer Connection website, at http://developer.apple.com/documentation/GraphicsImaging/Reference/CGImageSource/Reference/reference.html
    */
    private func createImageSource() -> Bool {
        
        guard imageSource == nil else {return true}
        // Compose absolute URL to file.
        let sourceURL = self.url.absoluteURL
        
        // Create a CGImageSource from the URL.
        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            return false
        }
        guard let _ = CGImageSourceGetType(imageSource) else {
            return false
        }
        self.imageSource = imageSource
        return true
    }
    
    //MARK: Loading
    
    // These are triggered automatically the first time relevant properties are requested, but can be invoked explicitly to force loading earlier.
    
    @discardableResult
    func loadMetadata() -> Bool {
        guard imageProperties == nil else {return true}
            
        // Get image properties.
        guard self.createImageSource() else {
            return false
        }
        
        // This code looks at the first image only.
        // To be truly general, we'd need to handle the possibility of an image source
        // having more than one image to offer us.
        //
        let index = 0
        imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource!, index, nil) as! [AnyHashable: Any]?
        
        // Return indicating success!
        return imageProperties != nil
    }
    
    func requestPreviewImage() {
        guard self.previewImage == nil else {return}
        type(of: self).previewLoadingOperationQueue.addOperation {
            guard self.createImageSource() else {return}
            let options: [AnyHashable: Any] = [
                // Ask ImageIO to create a thumbnail from the file's image data, if it can't find
                // a suitable existing thumbnail image in the file.  We could comment out the following
                // line if only existing thumbnails were desired for some reason (maybe to favor
                // performance over being guaranteed a complete set of thumbnails).
                kCGImageSourceCreateThumbnailFromImageIfAbsent as AnyHashable: true,
                kCGImageSourceThumbnailMaxPixelSize as AnyHashable: 160
            ]
            guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(self.imageSource!, 0, options as CFDictionary) else {return}
            let image = NSImage(cgImage: thumbnail, size: NSZeroSize)
            OperationQueue.main.addOperation{
                self.previewImage = image
            }
        }
    }
    
    
    //MARK: Debugging Assistance
    
    override var description: String {
        return "{ImageFile: \(self.url.absoluteString), tags=\(self.tagNames)}"
    }
    
    
}
