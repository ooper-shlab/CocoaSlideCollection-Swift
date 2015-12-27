# CocoaSlideCollection

## Version

1.0

## Requirements

### Build

Xcode 7.0, OS X 10.11

### Runtime

OS X 10.11

## About CocoaSlideCollection

CocoaSlideCollection demonstrates how to use the new NSCollectionView API added in OS X 10.11. Using an NSCollectionView, it enables browsing folders of image files, with support for custom NSCollectionViewLayouts, item selection and highlighting, grouping by image file tag with header and footer views, and drag-and-drop.

An AAPLBrowserWindowController manages a window and its NSCollectionView, and serves as the NSCollectionView's dataSource and delegate.  The collection of images to display is represented by an AAPLImageCollection that owns AAPLImageFiles and associated AAPLTags.  The AAPLImageCollection monitors its associated folder, and notifies the AAPLBrowserWindowController of the comings and goings of image files, so that the CollectionView can be updated accordingly.  Each AAPLImageFile model object is represented in the NSCollectionView by an AAPLSlide and its associated view tree.

CocoaSlideCollection implements and uses several custom NSCollectionViewLayout subclasses, that can arrange the slides in a variety of ways.

Checking the "Group by Tag" checkbox demonstrates the ability to group NSCollectionView items into sections, and give each section a header and footer view (currently only supported in the "Wrapped"/Flow layout).

See the Application Kit Release Notes and WWDC 2015 Session 225 - What's New in NSCollectionView for more information on using the new NSCollectionView APIs.

Copyright (C) 2015 Apple Inc. All rights reserved.
