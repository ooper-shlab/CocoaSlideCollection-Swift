//
//  AAPLFooterView.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/26.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information

    Abstract:
    This is the "FooterView" class declaration.
*/

import Cocoa

@objc(AAPLFooterView)
class AAPLFooterView: AAPLHeaderView {
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor(calibratedWhite: 0.85, alpha: 0.8).set()
        dirtyRect.fill(using: .sourceOver)
    }
    
}
