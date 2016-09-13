//
//  AAPLBrowserWindowController.swift
//  CocoaSlideCollection
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/12/21.
//
//
/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample‚Äôs licensing information

    Abstract:
    This is the browser window controller declaration.
*/

import Cocoa

@objc enum SlideLayoutKind: Int {
    case circular = 0
    case loop
    case scatter
    case wrapped
}

/*
Each browser window is managed by a AAPLBrowserWindowController, which
serves as its CollectionView's dataSource and delegate.  (The
CollectionView's dataSource and delegate outlets are wired up in
BrowserWindow.xib, so there is no need to set these properties in code.)
*/
@objc(AAPLBrowserWindowController)
class AAPLBrowserWindowController : NSWindowController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    // Model
    private var rootURL: URL!                                         // URL of the folder whose image files the browser is displaying
    var imageCollection: AAPLImageCollection?                   // the ImageFiles we found in the folder, which we can access as a flat list or grouped by AAPLTag
    
    //MARK: Outlets
    // Views
    @IBOutlet weak var imageCollectionView: NSCollectionView!  // a CollectionView that displays items ("slides") representing the image files
    @IBOutlet weak var statusTextField: NSTextField!           // a TextField that shows informative status
    
    // UI State
    private var _layoutKind: SlideLayoutKind = .circular                             // what kind of layout to use, per the above SlideLayoutKind enumeration
    private var _groupByTag: Bool = false                                        // YES if our imageCollectionView should show its items grouped by tag, with header and footer views (usable with Wrapped layout only)
    private var autoUpdateResponseSuspended: Bool = false                       // YES when we want to suppress our usual automatic KVO response to assets coming and going
    private var indexPathsOfItemsBeingDragged: Set<IndexPath> = []    // when our imageCollectionView is the source for a drag operation, this array of NSIndexPaths identifies the items that are being dragged within or out of it
    
    
    private let HEADER_VIEW_HEIGHT: CGFloat = 39
    private let FOOTER_VIEW_HEIGHT: CGFloat = 28
    
    private let selectionIndexPathsKey = "selectionIndexPaths"
    private let tagsKey = "tags"
    
    // Initializes a browser window that's pointed at the given folder URL.
    convenience init(rootURL newRootURL: URL) {
        self.init(windowNibName: "BrowserWindow")
        rootURL = (newRootURL as NSURL).copy() as! URL
        _groupByTag = false
        _layoutKind = SlideLayoutKind.wrapped
        
        // Create an AAPLImageCollection for browsing our assigned folder.
        imageCollection = AAPLImageCollection(rootURL: rootURL)
        
        /*
        Watch for changes in the imageCollection's imageFiles list.
        Whenever a new AAPLImageFile is added or removed,
        Key-Value Observing (KVO) will send us an
        -observeValueForKeyPath:ofObject:change:context: message, which we
        can respond to as needed to update the set of slides that we
        display.
        */
        self.startObservingImageCollection()
        
    }
    
    // This important method, which is invoked after the AAPLBrowserWindowController has finished loading its BrowserWindow.nib file, is where we perform some important setup of our NSCollectionView.
    override func windowDidLoad() {
        
        // Set the window's title to the name of the folder we're browsing.
        self.window?.title = rootURL.lastPathComponent
        
        // Set imageCollectionView.collectionViewLayout to match our desired layoutKind.
        self.updateLayout()
        
        // Give the CollectionView a backgroundView.  The CollectionView will insert this view behind its enclosing NSClipView, and automatically size it to always match the NSClipView's frame, producing a background that remains stationary as the content scrolls.
        let backgroundView = AAPLSlideTableBackgroundView(frame: NSMakeRect(0, 0, 100, 100))
        self.imageCollectionView.backgroundView = backgroundView
        
        // Watch for changes to the CollectionView's selection, just so we can update our status display.
        imageCollectionView.addObserver(self, forKeyPath: selectionIndexPathsKey, options: [], context: nil)
        
        // Start scanning our assigned folder for image files.
        imageCollection?.startOrRestartFileTreeScan()
        
        // Configure our CollectionView for drag-and-drop.
        self.registerForCollectionViewDragAndDrop()
    }
    
    private func registerForCollectionViewDragAndDrop() {
        
        // Register for the dropped object types we can accept.
        imageCollectionView.register(forDraggedTypes: [NSURLPboardType])
        
        // Enable dragging items from our CollectionView to other applications.
        imageCollectionView.setDraggingSourceOperationMask(.every, forLocal: false)
        
        // Enable dragging items within and into our CollectionView.
        imageCollectionView.setDraggingSourceOperationMask(.every, forLocal: true)
    }
    
    //MARK: Properties
    
    var groupByTag: Bool {
        get {
            return _groupByTag
        }
        
        set(flag) {
            if groupByTag != flag {
                /*
                We observe our imageCollection's properties differently, depending
                whether groupByTag is enabled.  So stop observing before we toggle
                the value of groupByTag, then start observing again afterward.
                */
                self.stopObservingImageCollection()
                _groupByTag = flag
                self.startObservingImageCollection()
                
                /*
                Tell our CollectionView to reload, since items will now be
                reorganized into sections (or not), and thus will be identified by
                different NSIndexPaths.
                */
                imageCollectionView.reloadData()
                
                if _groupByTag {
                    NSAnimationContext.current().duration = 0.0 // Suppress animation.
                    self.layoutKind = .wrapped // Only our Wrapped layout is designed to deal with sections.
                }
            }
        }
    }
    
    @objc dynamic var layoutKind: SlideLayoutKind {
        get {
            return _layoutKind
        }
        
        set(newLayoutKind) {
            if _layoutKind != newLayoutKind {
                if newLayoutKind != .wrapped && _groupByTag {
                    NSAnimationContext.current().duration = 0.0 // Suppress animation.
                    groupByTag = false
                }
                _layoutKind = newLayoutKind
                self.updateLayout()
            }
        }
    }
    
    private func updateLayout() {
        
        var layout: NSCollectionViewLayout? = nil
        switch layoutKind {
        case .circular: layout = AAPLCircularLayout()
        case .loop: layout = AAPLLoopLayout()
        case .scatter: layout = AAPLScatterLayout()
        case .wrapped: layout = AAPLWrappedLayout()
        }
        if let layout = layout {
            if NSAnimationContext.current().duration > 0.0 {
                NSAnimationContext.current().duration = 0.5
                imageCollectionView.animator().collectionViewLayout = layout
            } else {
                imageCollectionView.collectionViewLayout = layout
            }
        }
    }
    
    private func suspendAutoUpdateResponse() {
        autoUpdateResponseSuspended = true
    }
    
    private func resumeAutoUpdateResponse() {
        autoUpdateResponseSuspended = false
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as AnyObject? === imageCollectionView && keyPath == selectionIndexPathsKey {
            
            /*
            We're being notified that our imageCollectionView's
            "selectionIndexPaths" property has changed.  Update our status
            TextField with a summary (item count) of the new selection.
            */
            let newSelectedIndexPaths = imageCollectionView.selectionIndexPaths
            self.showStatus("\(newSelectedIndexPaths.count) items selected")
            
        } else if object as AnyObject? === imageCollection && !autoUpdateResponseSuspended {
            
            /*
            We're being notified that our imageCollection's contents have
            changed, and we haven't disabled our auto-update response, so we
            want to inform our imageCollectionView of the exact change that
            just took place.  Identify the change by examining the "object",
            "keyPath", and "change" dictionary we've been given, then handle
            the change accordingly.  For insertion or removal of items, the
            "change" dictionary will give us a set of "indexes" that specify
            what was added or removed from the parent "object" (which might be
            the imageCollection itself, or one of its AAPLTags).  Part of what
            we may need to do is map these indices to corresponding
            (section,item) NSIndexPaths.
            */
            
            let kind = change![NSKeyValueChangeKey.kindKey]! as! UInt
            if kind == NSKeyValueChange.insertion.rawValue || kind == NSKeyValueChange.removal.rawValue {
                
                let indexes = change![NSKeyValueChangeKey.indexesKey]! as! IndexSet
                var indexPaths: Set<IndexPath> = []
                if keyPath == imageFilesKey {
                    if object as AnyObject? === imageCollection {
                        
                        // Our imageCollection's "imageFiles" array changed.
                        indexes.forEach {itemIndex in
                            indexPaths.insert(IndexPath(item: itemIndex, section: 0))
                        }
                        
                    } else if let object = object as? AAPLTag {
                        
                        // An AAPLTag's "imageFiles" array changed.
                        if let sectionIndex = imageCollection?.tags.index(of: object) {
                            indexes.forEach {itemIndex in
                                indexPaths.insert(IndexPath(item: itemIndex, section: sectionIndex))
                            }
                        }
                        
                    }
                    
                    // Notify our imageCollectionView of the change.
                    if kind == NSKeyValueChange.insertion.rawValue {
                        self.handleImageFilesInsertedAtIndexPaths(indexPaths)
                    } else {
                        self.handleImageFilesRemovedAtIndexPaths(indexPaths)
                    }
                    
                } else if keyPath == tagsKey {
                    
                    // Our imageCollection's "tags" array changed.
                    if kind == NSKeyValueChange.insertion.rawValue {
                        self.handleTagsInsertedInCollectionAtIndexes(indexes)
                    } else {
                        self.handleTagsRemovedFromCollectionAtIndexes(indexes)
                    }
                }
                
            } else {
                // For NSKeyValueChangeSetting, we just reload everything.
                self.imageCollectionView.reloadData()
            }
        }
    }
    
    //MARK: Actions
    // Invoked by the "File" -> "Refresh" menu item.
    func refresh(_: AnyObject) {
        /*
        Ask our imageCollection to check for new, changed, and removed asset
        files.  This AAPLBrowserWindowController will be automatically notified
        of changes to the imageCollection via KVO, since we registered to
        observe the imageCollection's contents.
        */
        imageCollection?.startOrRestartFileTreeScan()
    }
    
    private func imageFileAtIndexPath(_ indexPath: IndexPath) -> AAPLImageFile? {
        if groupByTag {
            let tags = imageCollection?.tags ?? []
            let sectionIndex = (indexPath as NSIndexPath).section
            if sectionIndex < tags.count {
                return tags[sectionIndex].imageFiles[(indexPath as NSIndexPath).item]
            } else {
                return imageCollection?.untaggedImageFiles[(indexPath as NSIndexPath).item]
            }
        } else {
            return imageCollection?.imageFiles[(indexPath as NSIndexPath).item]
        }
    }
    
    
    //MARK: NSCollectionViewDataSource Methods
    
    // Each of these methods checks whether "groupByTag" is on, and modifies its behavior accordingly.
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        if groupByTag {
            return (imageCollection?.tags.count ?? 0) + 1  // +1 for the special "Untagged" section we put at the end
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if groupByTag {
            let tags = imageCollection?.tags ?? []
            if section < tags.count {
                // Return the number of ImageFiles in the AAPLTag with index "section".
                return tags[section].imageFiles.count
            } else {
                // Return the number of ImageFiles in the special "Untagged" section we put at the end
                return imageCollection?.untaggedImageFiles.count ?? 0
            }
        } else {
            // Return the number of ImageFiles in the collection (treated as a single, flat list).
            return imageCollection?.imageFiles.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        // Message back to the collectionView, asking it to make a @"Slide" item associated with the given item indexPath.  The collectionView will first check whether an NSNib or item Class has been registered with that name (via -registerNib:forItemWithIdentifier: or -registerClass:forItemWithIdentifier:).  Failing that, the collectionView will search for a .nib file named "Slide".  Since our .nib file is named "Slide.nib", no registration is necessary.
        let item = collectionView.makeItem(withIdentifier: "Slide", for: indexPath)
        let imageFile = self.imageFileAtIndexPath(indexPath)
        item.representedObject = imageFile
        
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> NSView {
        var identifier: String? = nil
        var content: String? = nil
        let tags = imageCollection?.tags ?? []
        let sectionIndex = (indexPath as NSIndexPath).section
        
        if sectionIndex < tags.count {
            let tag = tags[sectionIndex]
            if kind == NSCollectionElementKindSectionHeader {
                content = tag.name
            } else if kind == NSCollectionElementKindSectionFooter {
                content = "\(tag.imageFiles.count) image files tagged \"\(tag.name)\""
            }
        } else {
            if kind == NSCollectionElementKindSectionHeader {
                content = "(Untagged)"
            } else if kind == NSCollectionElementKindSectionFooter {
                content = "\(imageCollection?.untaggedImageFiles.count ?? 0) image files have no tags assigned"
            }
        }
        
        if kind == NSCollectionElementKindSectionHeader {
            identifier = "Header"
        } else if kind == NSCollectionElementKindSectionFooter {
            identifier = "Footer"
        }
        
        let view = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: identifier ?? "", for: indexPath)
        if let content = content, let view = view as? AAPLHeaderView {
            let titleTextField = view.titleTextField
            titleTextField?.stringValue = content
        }
        
        return view
    }
    
    
    //MARK: NSCollectionViewDelegateFlowLayout Methods
    
    // Implementing this delegate method tells a NSCollectionViewFlowLayout (such as our AAPLWrappedLayout) what size to make a "Header" supplementary view.  (The actual size will be clipped to the CollectionView's width.)
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        return groupByTag ? NSMakeSize(10000, HEADER_VIEW_HEIGHT) : NSZeroSize; // If groupByTag is NO, we don't want to show a header.
    }
    
    // Implementing this delegate method tells a NSCollectionViewFlowLayout (such as our AAPLWrappedLayout) what size to make a "Footer" supplementary view.  (The actual size will be clipped to the CollectionView's width.)
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForFooterInSection section: Int) -> NSSize {
        return groupByTag ? NSMakeSize(10000, FOOTER_VIEW_HEIGHT) : NSZeroSize; // If groupByTag is NO, we don't want to show a footer.
    }
    
    
    //MARK: NSCollectionViewDelegate Drag-and-Drop Methods
    
    
    /*******************/
    /* Dragging Source */
    /*******************/
    
    /*
    1. When a CollectionView wants to begin a drag operation for some of its
    items, it first sends this message to its delegate.  The delegate may return
    YES to allow the proposed drag to begin, or NO to prevent it.  We want to
    allow the user to drag any and all items in the CollectionView, so we
    unconditionally return YES here.  If you wish, however, you can return NO
    under certain circumstances, to prevent the items specified by "indexPaths"
    from being dragged.
    */
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
        return true
    }
    
    /*
    2. If the above method allows the drag to begin, the CollectionView will invoke
    this method once per item to be dragged, to request a pasteboard writer for
    the item's underlying model object.  Some kinds of model objects (for
    example, NSURL) are themselves suitable pasteboard writers.
    */
    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        let imageFile = self.imageFileAtIndexPath(indexPath)!
        return imageFile.url.absoluteURL as NSPasteboardWriting?; // An NSURL can be a pasteboard writer, but must be returned as an absolute URL.
    }
    
    /*
    3. After obtaining a pasteboard writer for each item to be dragged, the
    CollectionView will invoke this method to notify you that the drag is
    beginning.  You aren't required to implement this delegate method, but it
    can provide a useful hook for one particular start-of-drag action you might
    want to perform: saving a copy fo the passed the indexPaths as an indication
    to yourself that the drag began in this CollectionView, which will prove
    useful if the same CollectionView ends up being the drop destination.
    */
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
        
        /*
        Remember the indexPaths we're dragging, in case we end up being the drag
        destination too.  Knowing that a drop originated from this
        CollectionView will enable us to handle it more efficiently, and with
        a "move items" operation instead of a
        */
        indexPathsOfItemsBeingDragged = indexPaths
        
        // Indicate dragging state in our status TextField.
        self.showStatus("Dragging \(indexPaths.count) items")
    }
    
    /*
    If this CollectionView ends up also being the dragging destination, we'll
    receive the "Dragging Destination" messages as implemented below, before
    the dragging session ends.
    */
    
    /*
    6. Whether the drag is accepted, or the drag operation is cancelled, the
    CollectionView always sends this mesage to conclude the drag session.  It's
    a good place to perform any necessary cleanup, such as clearing the
    "indexPathsOfItemsBeingDragged" we saved in the
    -collectionView:draggingSession:willBeginAtPoint:forItemsAtIndexPaths:
    method, above.
    */
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
        
        // Clear the dragging indexPaths we saved earlier.
        indexPathsOfItemsBeingDragged = []
        
        // Indicate dragging state in our status TextField.
        self.showStatus("Dragging ended")
    }
    
    
    /************************/
     /* Dragging Destination */
     /************************/
     
     /*
     4. When the user drags something around a CollectionView (whether the dragging
     source is the same CollectionView or some other view, potentially in a
     different process), the CollectionView will repeatedly invoke this method to
     propose dropping the dragging items at various places within within itself.
     (If the user mouses out of the CollectionView, the CollectionView stops
     sending this message.  If the user mouses back into the CollectionView, the
     CollectionView starts sending this messsage again.)  You return an
     NSDragOperation mask to specify what kinds of drag operations should be
     allowed for the proposed destination.  You may also alter the
     proposedDropOperation and proposedDropIndexPath through the provided
     pointers, if desired.
     */
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionViewDropOperation>) -> NSDragOperation {
    
        /*
        Interpret the proposedDropIndexPath in the context of the
        proposedDropOperation, and decide whether it's an operation we want to
        allow.  A proposedDropOperation of NSCollectionViewDropOn indicates that
        the user is hovering over an existing item idntified by the
        proposedDropIndexPath.  A proposedDropOperation of
        NSCollectionViewDropBefore indicates that the user is hovering in a gap
        between items, and inserting the dropped items at proposedDropIndexPath
        would place the dropped items in that gap.  If you allow the user to
        manually order items, you might accept a "DropBefore" operation as
        proposed.  If your items are automatically sorted according to some
        criteria, you might disregard the proposedDropIndexPath, and simply
        accept the drop as a drop into the CollectionView as a whole, choosing
        your own appropriate index paths at which to insert the dropped items.
        
        In this example, we want to allow drag-and-drop as a means of manually
        reordering items, and our items aren't able to act as containers, so we
        allow dropping between items only, not dropping onto them.
        */
        
        // Evaluate and possibly override the proposed drop operation.
        var proposedActionDescription = String(format: "Validate drop %@ item at indexPath=%@", StringFromCollectionViewDropOperation(proposedDropOperation.pointee), StringFromCollectionViewIndexPath(proposedDropIndexPath.pointee as IndexPath))
        if proposedDropOperation.pointee == .on {
            proposedDropOperation.pointee = .before
            proposedActionDescription += " -- changed to drop before \(StringFromCollectionViewIndexPath(proposedDropIndexPath.pointee as IndexPath))"
        }
        
        // Indicate dragging state in our status TextField.
        self.showStatus(proposedActionDescription)
        
        /*
        If we're dragging items around within the CollectionView (i.e. this
        CollectionView is also the dragging source), the operation is Move.
        If not, the operation is Copy.
        
        This example doesn't yet support dragging items within a CollectionView
        in "Group by Tag" mode, so return NSDragOperationNone if that's what's
        proposed.
        */
        if !indexPathsOfItemsBeingDragged.isEmpty {
            return groupByTag ? NSDragOperation() : NSDragOperation.move
        } else {
            return NSDragOperation.copy
        }
    }
    
    /*
    5. If the user commits the proposed drop operation (by releasing the mouse
    button), the CollectionView invokes this method to instruct its delegate to
    make the proposed edit.  Your implementation has the important
    responsibility of (1) modifying your model as proposed, and then
    (2) notifying the CollectionView of the edits.  Return YES if you completed
    the drop successfully, NO if you could not complete the drop.
    */
    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionViewDropOperation) -> Bool {
        
        var result = false
        let proposedActionDescription = String(format: "Accept drop of %lu items from %@, %@ item at indexPath=%@",
            UInt(draggingInfo.numberOfValidItemsForDrop),
            !indexPathsOfItemsBeingDragged.isEmpty ? "self" : "elsewhere",
            StringFromCollectionViewDropOperation(dropOperation),
            StringFromCollectionViewIndexPath(indexPath))
        self.showStatus(proposedActionDescription)
        
        /*
        Suspend our usual KVO response to ImageCollection changes.  We want to
        notify the CollectionView of updates manually, so we can animate a
        "move" instead of a "delete" and "insert".
        */
        self.suspendAutoUpdateResponse()
        
        // Is our own imageCollectionView the dragging source?
        if !indexPathsOfItemsBeingDragged.isEmpty {
            
            // Yes, existing items are being dragged within our imageCollectionView.
            
            if groupByTag {
                
                /*
                This example doesn't yet support dragging items within a
                CollectionView in "Group by Tag" mode, so return NO if that's
                what's proposed.
                */
                result = false
                
            } else {
                
                let indexPathsOfItemsBeingDraggedSorted = indexPathsOfItemsBeingDragged.sorted{($0 as NSIndexPath).compare($1) == .orderedAscending}
                /*
                Walk forward through fromItemIndex values > toItemIndex, to keep
                our "from" and "to" indexes valid as we go, moving items one at
                a time.
                */
                var toItemIndex = (indexPath as NSIndexPath).item
                for fromIndexPath in indexPathsOfItemsBeingDraggedSorted {
                    let fromItemIndex = (fromIndexPath as NSIndexPath).item
                    if fromItemIndex > toItemIndex {
                        
                        /*
                        For each step: First, modify our model.
                        */
                        imageCollection?.moveImageFileFromIndex(fromItemIndex, toIndex: toItemIndex)
                        
                        /*
                        Next, notify the CollectionView of the change we just
                        made to our model.
                        */
                        imageCollectionView.animator().moveItem(at: IndexPath(item: fromItemIndex, section: (indexPath as NSIndexPath).section), to: IndexPath(item: toItemIndex, section: (indexPath as NSIndexPath).section))
                        
                        // Advance to maintain moved items in their original order.
                        toItemIndex += 1
                    }
                }
                
                /*
                Walk backward through fromItemIndex values < toItemIndex, to
                keep our "from" and "to" indexes valid as we go, moving items
                one at a time.
                */
                var adjustedToItemIndex = (indexPath as NSIndexPath).item - 1
                for fromIndexPath in indexPathsOfItemsBeingDraggedSorted.lazy.reversed() {
                    let fromItemIndex = (fromIndexPath as NSIndexPath).item
                    if fromItemIndex < adjustedToItemIndex {
                        
                        /*
                        For each step: First, modify our model.
                        */
                        imageCollection?.moveImageFileFromIndex(fromItemIndex, toIndex: adjustedToItemIndex)
                        
                        /*
                        Next, notify the CollectionView of the change we just
                        made to our model.
                        */
                        let adjustedToIndexPath = IndexPath(item: adjustedToItemIndex, section: (indexPath as NSIndexPath).section)
                        imageCollectionView.animator().moveItem(at: IndexPath(item: fromItemIndex, section: (indexPath as NSIndexPath).section), to: adjustedToIndexPath)
                        
                        // Retreat to maintain moved items in their original order.
                        adjustedToItemIndex -= 1
                    }
                }
                
                // We did it!
                result = true
            }
            
        } else {
            
            // Items are being dragged from elsewhere into our CollectionView.
            
            /*
            Examine the items to be dropped, as provided by the draggingInfo
            object.  Accumulate the URLs among them into a "droppedObjects"
            array.
            */
            var droppedObjects: [URL] = []
            draggingInfo.enumerateDraggingItems(options: [], for: collectionView, classes: [URL.self as! AnyObject.Type], searchOptions: [NSPasteboardURLReadingFileURLsOnlyKey: true]) {draggingItem, idx, stop in
                
                if let url = draggingItem.item as? URL {
                    droppedObjects.append(url)
                }
            }
            
            /*
            For each dropped URL:
            
            1. Create a corresponding AAPLImageFile.
            2. Insert the AAPLImageFile at the designated point in our
            imageCollection.
            3. Notify our CollectionView of the insertion.
            
            We check first whether the colleciton already contains an ImageFile
            with the given URL, and disallow duplicates.
            */
            let insertionIndex = (indexPath as NSIndexPath).item
            var errors: [NSError] = []
            for url in droppedObjects {
                var imageFile = imageCollection?.imageFileForURL(url)
                if imageFile == nil {
                    
                    /*
                    Copy the image file from the source URL into our
                    imageCollection's folder.
                    */
                    guard let targetURL = imageCollection?.rootURL?.appendingPathComponent(url.lastPathComponent, isDirectory: false) else {
                        fatalError()
                    }
                    do {
                        try FileManager.default.copyItem(at: url, to: targetURL)
                        
                        /*
                        Now create and insert an ImageFile that references the
                        targetURL we copied to.
                        */
                        imageFile = AAPLImageFile(URL: targetURL)
                        /*
                        For each item: First, modify our model.
                        */
                        imageCollection?.insertImageFile(imageFile!, atIndex: insertionIndex)
                        
                        /*
                        Next, notify the CollectionView of the change we just
                        made to our model.
                        */
                        collectionView.animator().insertItems(at: [indexPath])
                        
                        // We succeeded in accepting at least one item.
                        result = true
                    } catch let error as NSError {
                        /*
                        Copy failed.  Remember the error, and notify the user of
                        just the first failure, instead of pestering them about
                        each of potentially several failures.
                        */
                        errors.append(error)
                    }
                }
            }
            
            if !errors.isEmpty {
                imageCollectionView.presentError(errors[0], modalFor: imageCollectionView.window!, delegate: nil, didPresent: nil, contextInfo: nil)
            }
        }
        
        // Resume normal KVO handling.
        self.resumeAutoUpdateResponse()
        
        // Return indicating success or failure.
        return result
    }
    
    
    //MARK: Teardown
    
    func windowWillClose(_ notification: Notification) {
        imageCollection?.stopWatchingFolder() // Break retain cycle, allowing teardown.
        self.stopObservingImageCollection()
        imageCollectionView.removeObserver(self, forKeyPath: selectionIndexPathsKey)
    }
    
    private func showStatus(_ statusMessage: String) {
        statusTextField.stringValue = statusMessage
    }
    
    private func startObservingImageCollection() {
        /*
        Sign up for Key-Value Observing (KVO) notifications, that will tell us
        when the content of our imageCollection changes.  If we are showing
        its ImageFiles grouped by tag, we want to observe the imageCollection's
        "tags" array, and the "imageFiles" array of each AAPLTag.  If we are
        showing our imageCollection's ImageFiles without grouping, we instead
        want to simply observe the imageCollection's "imageFiles" array.
        
        Whenever a change occurs, KVO will send us an
        -observeValueForKeyPath:ofObject:change:context: message, which we
        can respond to as needed to update the set of slides that we
        display.
        */
        if groupByTag {
            imageCollection?.addObserver(self, forKeyPath: tagsKey, options: [], context: nil)
            for tag in imageCollection?.tags ?? [] {
                tag.addObserver(self, forKeyPath: imageFilesKey, options: [], context: nil)
            }
        } else {
            imageCollection?.addObserver(self, forKeyPath: imageFilesKey, options: [], context: nil)
        }
    }
    
    private func stopObservingImageCollection() {
        if groupByTag {
            imageCollection?.removeObserver(self, forKeyPath: tagsKey)
            for tag in imageCollection?.tags ?? [] {
                tag.removeObserver(self, forKeyPath: imageFilesKey)
            }
        } else {
            imageCollection?.removeObserver(self, forKeyPath: imageFilesKey)
        }
    }
    
    private func handleImageFilesInsertedAtIndexPaths(_ indexPaths: Set<IndexPath>) {
        NSAnimationContext.current().duration = 0.25
        self.imageCollectionView.animator().insertItems(at: indexPaths)
    }
    
    private func handleImageFilesRemovedAtIndexPaths(_ indexPaths: Set<IndexPath>) {
        NSAnimationContext.current().duration = 0.25
        self.imageCollectionView.animator().deleteItems(at: indexPaths)
    }
    
    private func handleTagsInsertedInCollectionAtIndexes(_ indexes: IndexSet) {
        NSAnimationContext.current().duration = 0.25
        self.imageCollectionView.animator().insertSections(indexes)
    }
    
    private func handleTagsRemovedFromCollectionAtIndexes(_ indexes: IndexSet) {
        NSAnimationContext.current().duration = 0.25
        self.imageCollectionView?.animator().deleteSections(indexes)
    }
    
}

private func StringFromCollectionViewDropOperation(_ dropOperation: NSCollectionViewDropOperation) -> String {
    switch dropOperation {
    case .before:
        return "before";
        
    case .on:
        return "on";
        
    }
}

private func StringFromCollectionViewIndexPath(_ indexPath: IndexPath?) -> String {
    if let indexPath = indexPath , (indexPath as NSIndexPath).length == 2 {
        return "(\((indexPath as NSIndexPath).section),\((indexPath as NSIndexPath).item))"
    } else {
        return "(nil)"
    }
}
