//
//  AAPLTag.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/23.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    This is the "Tag" class declaration.
*/

import Cocoa

// An AAPLTag is a label string that can be applied to ImageFiles.  An AAPLImageCollection has a list of Tags, each of which has associated ImageFiles.
@objc(AAPLTag)
class AAPLTag: NSObject {
    private(set) var name: String                 // the tag string (e.g. "Vacation")
    @objc dynamic private(set) var imageFiles: [AAPLImageFile] = []     // the ImageFiles that have this tag, ordered for display using our desired sort
    
    init(name newName: String) {
        name = newName
        super.init()
    }
    
    func insertImageFile(_ imageFile: AAPLImageFile) {
        let insertionIndex = imageFiles.indexOf(imageFile, inSortedRange: imageFiles.startIndex..<imageFiles.endIndex) {imageFile1, imageFile2 in
            return imageFile1.filenameWithoutExtension!.caseInsensitiveCompare(imageFile2.filenameWithoutExtension!)
        }
        imageFiles.insert(imageFile, at: insertionIndex)
    }
    
    override var description: String {
        return "{Tag: \(self.name)}"
    }
    
}
