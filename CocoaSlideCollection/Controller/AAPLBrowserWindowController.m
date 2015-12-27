/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the browser window controller implementation.
*/

#import "AAPLBrowserWindowController.h"
#import "AAPLHeaderView.h"
#import "AAPLImageCollection.h"
#import "AAPLImageFile.h"
#import "AAPLSlideCarrierView.h"
#import "AAPLSlideTableBackgroundView.h"
#import "AAPLTag.h"
#import "AAPLSlideLayout.h"
#import "AAPLCircularLayout.h"
#import "AAPLLoopLayout.h"
#import "AAPLScatterLayout.h"
#import "AAPLWrappedLayout.h"

#define HEADER_VIEW_HEIGHT  39
#define FOOTER_VIEW_HEIGHT  28

static NSString *selectionIndexPathsKey = @"selectionIndexPaths";
static NSString *tagsKey = @"tags";

static NSString *StringFromCollectionViewDropOperation(NSCollectionViewDropOperation dropOperation);
static NSString *StringFromCollectionViewIndexPath(NSIndexPath *indexPath);

@interface AAPLBrowserWindowController (Internals)

- (void)showStatus:(NSString *)statusMessage;

- (void)startObservingImageCollection;
- (void)stopObservingImageCollection;

- (void)handleImageFilesInsertedAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths;
- (void)handleImageFilesRemovedAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths;

- (void)handleTagsInsertedInCollectionAtIndexes:(NSIndexSet *)indexes;
- (void)handleTagsRemovedFromCollectionAtIndexes:(NSIndexSet *)indexes;

@end

@implementation AAPLBrowserWindowController

- (id)initWithRootURL:(NSURL *)newRootURL {
    self = [super initWithWindowNibName:@"BrowserWindow"];
    if (self) {
        rootURL = [newRootURL copy];
        groupByTag = NO;
        layoutKind = SlideLayoutKindWrapped;

        // Create an AAPLImageCollection for browsing our assigned folder.
        imageCollection = [[AAPLImageCollection alloc] initWithRootURL:rootURL];

        /*
            Watch for changes in the imageCollection's imageFiles list.
            Whenever a new AAPLImageFile is added or removed,
            Key-Value Observing (KVO) will send us an
            -observeValueForKeyPath:ofObject:change:context: message, which we
            can respond to as needed to update the set of slides that we
            display.
        */
        [self startObservingImageCollection];
    }

    return self;
}

// This important method, which is invoked after the AAPLBrowserWindowController has finished loading its BrowserWindow.nib file, is where we perform some important setup of our NSCollectionView.
- (void)windowDidLoad {
    
    // Set the window's title to the name of the folder we're browsing.
    self.window.title = rootURL.lastPathComponent;
    
    // Set imageCollectionView.collectionViewLayout to match our desired layoutKind.
    [self updateLayout];

    // Give the CollectionView a backgroundView.  The CollectionView will insert this view behind its enclosing NSClipView, and automatically size it to always match the NSClipView's frame, producing a background that remains stationary as the content scrolls.
    NSView *backgroundView = [[AAPLSlideTableBackgroundView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
    self.imageCollectionView.backgroundView = backgroundView;

    // Watch for changes to the CollectionView's selection, just so we can update our status display.
    [imageCollectionView addObserver:self forKeyPath:selectionIndexPathsKey options:0 context:NULL];

    // Start scanning our assigned folder for image files.
    [imageCollection startOrRestartFileTreeScan];

    // Configure our CollectionView for drag-and-drop.
    [self registerForCollectionViewDragAndDrop];
}

- (void)registerForCollectionViewDragAndDrop {
    // Register for the dropped object types we can accept.
    [imageCollectionView registerForDraggedTypes:[NSArray arrayWithObject:NSURLPboardType]];

    // Enable dragging items from our CollectionView to other applications.
    [imageCollectionView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
    
    // Enable dragging items within and into our CollectionView.
    [imageCollectionView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
}

@synthesize imageCollectionView;
@synthesize statusTextField;

- (BOOL)groupByTag {
    return groupByTag;
}

- (void)setGroupByTag:(BOOL)flag {
    if (groupByTag != flag) {
        /*
            We observe our imageCollection's properties differently, depending
            whether groupByTag is enabled.  So stop observing before we toggle
            the value of groupByTag, then start observing again afterward.
        */
        [self stopObservingImageCollection];
        groupByTag = flag;
        [self startObservingImageCollection];

        /*
            Tell our CollectionView to reload, since items will now be
            reorganized into sections (or not), and thus will be identified by
            different NSIndexPaths.
        */
        [imageCollectionView reloadData];

        if (groupByTag) {
            [[NSAnimationContext currentContext] setDuration:0.0]; // Suppress animation.
            [self setLayoutKind:SlideLayoutKindWrapped]; // Only our Wrapped layout is designed to deal with sections.
        }
    }
}

- (SlideLayoutKind)layoutKind {
    return layoutKind;
}

- (void)setLayoutKind:(SlideLayoutKind)newLayoutKind {
    if (layoutKind != newLayoutKind) {
        if (newLayoutKind != SlideLayoutKindWrapped && groupByTag) {
            [[NSAnimationContext currentContext] setDuration:0.0]; // Suppress animation.
            [self setGroupByTag:NO];
        }
        layoutKind = newLayoutKind;
        [self updateLayout];
    }
}

- (void)updateLayout {
    
    NSCollectionViewLayout *layout = nil;
    switch (layoutKind) {
        case SlideLayoutKindCircular: layout = [[AAPLCircularLayout alloc] init]; break;
        case SlideLayoutKindLoop: layout = [[AAPLLoopLayout alloc] init]; break;
        case SlideLayoutKindScatter: layout = [[AAPLScatterLayout alloc] init]; break;
        case SlideLayoutKindWrapped: layout = [[AAPLWrappedLayout alloc] init]; break;
    }
    if (layout) {
        if (NSAnimationContext.currentContext.duration > 0.0) {
            NSAnimationContext.currentContext.duration = 0.5;
            imageCollectionView.animator.collectionViewLayout = layout;
        } else {
            imageCollectionView.collectionViewLayout = layout;
        }
    }
}

- (void)suspendAutoUpdateResponse {
    autoUpdateResponseSuspended = YES;
}

- (void)resumeAutoUpdateResponse {
    autoUpdateResponseSuspended = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == imageCollectionView && [keyPath isEqual:selectionIndexPathsKey]) {
        
        /*
            We're being notified that our imageCollectionView's
            "selectionIndexPaths" property has changed.  Update our status
            TextField with a summary (item count) of the new selection.
        */
        NSSet<NSIndexPath *> *newSelectedIndexPaths = imageCollectionView.selectionIndexPaths;
        [self showStatus:[NSString stringWithFormat:@"%lu items selected", (unsigned long)(newSelectedIndexPaths.count)]];

    } else if (object == imageCollection && !autoUpdateResponseSuspended) {

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

        NSKeyValueChange kind = [change[NSKeyValueChangeKindKey] integerValue];
        if (kind == NSKeyValueChangeInsertion || kind == NSKeyValueChangeRemoval) {
            
            NSIndexSet *indexes = change[@"indexes"];
            NSMutableSet<NSIndexPath *> *indexPaths = [NSMutableSet<NSIndexPath *> setWithCollectionViewIndexPaths:[NSArray array]];
            if ([keyPath isEqual:imageFilesKey]) {
                if (object == imageCollection) {

                    // Our imageCollection's "imageFiles" array changed.
                    [indexes enumerateIndexesUsingBlock:^(NSUInteger itemIndex, BOOL *stop) {
                        [indexPaths addObject:[NSIndexPath indexPathForItem:itemIndex inSection:0]];
                    }];
                    
                } else if ([object isKindOfClass:[AAPLTag class]]) {

                    // An AAPLTag's "imageFiles" array changed.
                    NSUInteger sectionIndex = [imageCollection.tags indexOfObject:object];
                    if (sectionIndex != NSNotFound) {
                        [indexes enumerateIndexesUsingBlock:^(NSUInteger itemIndex, BOOL *stop) {
                            [indexPaths addObject:[NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex]];
                        }];
                    }
                
                }

                // Notify our imageCollectionView of the change.
                if (kind == NSKeyValueChangeInsertion) {
                    [self handleImageFilesInsertedAtIndexPaths:indexPaths];
                } else {
                    [self handleImageFilesRemovedAtIndexPaths:indexPaths];
                }
                
            } else if ([keyPath isEqual:tagsKey]) {

                // Our imageCollection's "tags" array changed.
                if (kind == NSKeyValueChangeInsertion) {
                    [self handleTagsInsertedInCollectionAtIndexes:indexes];
                } else {
                    [self handleTagsRemovedFromCollectionAtIndexes:indexes];
                }
            }

        } else {
            // For NSKeyValueChangeSetting, we just reload everything.
            [self.imageCollectionView reloadData];
        }
    }
}

// Invoked by the "File" -> "Refresh" menu item.
- (void)refresh:(id)sender {
    /*
        Ask our imageCollection to check for new, changed, and removed asset
        files.  This AAPLBrowserWindowController will be automatically notified
        of changes to the imageCollection via KVO, since we registered to
        observe the imageCollection's contents.
    */
    [imageCollection startOrRestartFileTreeScan];
}

- (AAPLImageFile *)imageFileAtIndexPath:(NSIndexPath *)indexPath {
    if (groupByTag) {
        NSArray<AAPLTag *> *tags = imageCollection.tags;
        NSInteger sectionIndex = indexPath.section;
        if (sectionIndex < tags.count) {
            return tags[sectionIndex].imageFiles[indexPath.item];
        } else {
            return imageCollection.untaggedImageFiles[indexPath.item];
        }
    } else {
        return imageCollection.imageFiles[indexPath.item];
    }
}


#pragma mark NSCollectionViewDataSource Methods

// Each of these methods checks whether "groupByTag" is on, and modifies its behavior accordingly.

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
    if (groupByTag) {
        return imageCollection.tags.count + 1;  // +1 for the special "Untagged" section we put at the end
    } else {
        return 1;
    }
}

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (groupByTag) {
        NSArray<AAPLTag *> *tags = imageCollection.tags;
        if (section < tags.count) {
            // Return the number of ImageFiles in the AAPLTag with index "section".
            return tags[section].imageFiles.count;
        } else {
            // Return the number of ImageFiles in the special "Untagged" section we put at the end
            return imageCollection.untaggedImageFiles.count;
        }
    } else {
        // Return the number of ImageFiles in the collection (treated as a single, flat list).
        return imageCollection.imageFiles.count;
    }
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
    // Message back to the collectionView, asking it to make a @"Slide" item associated with the given item indexPath.  The collectionView will first check whether an NSNib or item Class has been registered with that name (via -registerNib:forItemWithIdentifier: or -registerClass:forItemWithIdentifier:).  Failing that, the collectionView will search for a .nib file named "Slide".  Since our .nib file is named "Slide.nib", no registration is necessary.
    NSCollectionViewItem *item = [collectionView makeItemWithIdentifier:@"Slide" forIndexPath:indexPath];
    AAPLImageFile *imageFile = [self imageFileAtIndexPath:indexPath];
    item.representedObject = imageFile;

    return item;
}

- (nonnull NSView *)collectionView:(nonnull NSCollectionView *)collectionView viewForSupplementaryElementOfKind:(nonnull NSString *)kind atIndexPath:(nonnull NSIndexPath *)indexPath {
    NSString *identifier = nil;
    NSString *content = nil;
    NSArray<AAPLTag *> *tags = imageCollection.tags;
    NSInteger sectionIndex = indexPath.section;

    if (sectionIndex < tags.count) {
        AAPLTag *tag = tags[sectionIndex];
        if ([kind isEqual:NSCollectionElementKindSectionHeader]) {
            content = tag.name;
        } else if ([kind isEqual:NSCollectionElementKindSectionFooter]) {
            content = [NSString stringWithFormat:@"%lu image files tagged \"%@\"", (unsigned long)(tag.imageFiles.count), tag.name];
        }
    } else {
        if ([kind isEqual:NSCollectionElementKindSectionHeader]) {
            content = @"(Untagged)";
        } else if ([kind isEqual:NSCollectionElementKindSectionFooter]) {
            content = [NSString stringWithFormat:@"%lu image files have no tags assigned", (unsigned long)(imageCollection.untaggedImageFiles.count)];
        }
    }
    
    if ([kind isEqual:NSCollectionElementKindSectionHeader]) {
        identifier = @"Header";
    } else if ([kind isEqual:NSCollectionElementKindSectionFooter]) {
        identifier = @"Footer";
    }

    id view = identifier ? [collectionView makeSupplementaryViewOfKind:kind withIdentifier:identifier forIndexPath:indexPath] : nil;
    if (content && [view isKindOfClass:[AAPLHeaderView class]]) {
        NSTextField *titleTextField = [(AAPLHeaderView *)view titleTextField];
        titleTextField.stringValue = content;
    }

    return view;
}


#pragma mark NSCollectionViewDelegateFlowLayout Methods

// Implementing this delegate method tells a NSCollectionViewFlowLayout (such as our AAPLWrappedLayout) what size to make a "Header" supplementary view.  (The actual size will be clipped to the CollectionView's width.)
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return groupByTag ? NSMakeSize(10000, HEADER_VIEW_HEIGHT) : NSZeroSize; // If groupByTag is NO, we don't want to show a header.
}

// Implementing this delegate method tells a NSCollectionViewFlowLayout (such as our AAPLWrappedLayout) what size to make a "Footer" supplementary view.  (The actual size will be clipped to the CollectionView's width.)
- (NSSize)collectionView:(NSCollectionView *)collectionView layout:(NSCollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return groupByTag ? NSMakeSize(10000, FOOTER_VIEW_HEIGHT) : NSZeroSize; // If groupByTag is NO, we don't want to show a footer.
}


#pragma mark NSCollectionViewDelegate Drag-and-Drop Methods


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
- (BOOL)collectionView:(NSCollectionView *)collectionView canDragItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths withEvent:(NSEvent *)event {
    return YES;
}

/*
 2. If the above method allows the drag to begin, the CollectionView will invoke
    this method once per item to be dragged, to request a pasteboard writer for
    the item's underlying model object.  Some kinds of model objects (for
    example, NSURL) are themselves suitable pasteboard writers.
*/
- (id <NSPasteboardWriting>)collectionView:(NSCollectionView *)collectionView pasteboardWriterForItemAtIndexPath:(NSIndexPath *)indexPath {
    AAPLImageFile *imageFile = [self imageFileAtIndexPath:indexPath];
    return imageFile.url.absoluteURL; // An NSURL can be a pasteboard writer, but must be returned as an absolute URL.
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
- (void)collectionView:(NSCollectionView *)collectionView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    
    /*
        Remember the indexPaths we're dragging, in case we end up being the drag
        destination too.  Knowing that a drop originated from this
        CollectionView will enable us to handle it more efficiently, and with
        a "move items" operation instead of a
    */
    indexPathsOfItemsBeingDragged = [indexPaths copy];

    // Indicate dragging state in our status TextField.
    [self showStatus:[NSString stringWithFormat:@"Dragging %lu items", (unsigned long)(indexPaths.count)]];
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
- (void)collectionView:(NSCollectionView *)collectionView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint dragOperation:(NSDragOperation)operation {

    // Clear the dragging indexPaths we saved earlier.
    indexPathsOfItemsBeingDragged = nil;

    // Indicate dragging state in our status TextField.
    [self showStatus:@"Dragging ended"];
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
- (NSDragOperation)collectionView:(NSCollectionView *)collectionView validateDrop:(id <NSDraggingInfo>)draggingInfo proposedIndexPath:(NSIndexPath **)proposedDropIndexPath dropOperation:(NSCollectionViewDropOperation *)proposedDropOperation {
    
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
    NSString *proposedActionDescription = [NSString stringWithFormat:@"Validate drop %@ item at indexPath=%@", StringFromCollectionViewDropOperation(*proposedDropOperation), StringFromCollectionViewIndexPath(*proposedDropIndexPath)];
    if (*proposedDropOperation == NSCollectionViewDropOn) {
        *proposedDropOperation = NSCollectionViewDropBefore;
        proposedActionDescription = [proposedActionDescription stringByAppendingFormat:@" -- changed to drop before %@", StringFromCollectionViewIndexPath(*proposedDropIndexPath)];
    }

    // Indicate dragging state in our status TextField.
    [self showStatus:proposedActionDescription];

    /*
        If we're dragging items around within the CollectionView (i.e. this
        CollectionView is also the dragging source), the operation is Move.
        If not, the operation is Copy.
     
        This example doesn't yet support dragging items within a CollectionView
        in "Group by Tag" mode, so return NSDragOperationNone if that's what's
        proposed.
    */
    if (indexPathsOfItemsBeingDragged) {
        return groupByTag ? NSDragOperationNone : NSDragOperationMove;
    } else {
        return NSDragOperationCopy;
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
- (BOOL)collectionView:(NSCollectionView *)collectionView acceptDrop:(id <NSDraggingInfo>)draggingInfo indexPath:(NSIndexPath *)indexPath dropOperation:(NSCollectionViewDropOperation)dropOperation {

    BOOL result = NO;
    NSString *proposedActionDescription = [NSString stringWithFormat:@"Accept drop of %lu items from %@, %@ item at indexPath=%@", (unsigned long)[draggingInfo numberOfValidItemsForDrop], indexPathsOfItemsBeingDragged ? @"self" : @"elsewhere", StringFromCollectionViewDropOperation(dropOperation), StringFromCollectionViewIndexPath(indexPath)];
    [self showStatus:proposedActionDescription];

    /*
        Suspend our usual KVO response to ImageCollection changes.  We want to
        notify the CollectionView of updates manually, so we can animate a
        "move" instead of a "delete" and "insert".
    */
    [self suspendAutoUpdateResponse];
    
    // Is our own imageCollectionView the dragging source?
    if (indexPathsOfItemsBeingDragged) {

        // Yes, existing items are being dragged within our imageCollectionView.
        
        if (groupByTag) {

            /*
                This example doesn't yet support dragging items within a
                CollectionView in "Group by Tag" mode, so return NO if that's
                what's proposed.
            */
            result = NO;

        } else {
            
            /*
                Walk forward through fromItemIndex values > toItemIndex, to keep
                our "from" and "to" indexes valid as we go, moving items one at
                a time.
            */
            __block NSInteger toItemIndex = indexPath.item;
            [indexPathsOfItemsBeingDragged enumerateIndexPathsWithOptions:0 usingBlock:^(NSIndexPath *fromIndexPath, BOOL *stop) {
                NSInteger fromItemIndex = fromIndexPath.item;
                if (fromItemIndex > toItemIndex) {
                    
                    /*
                        For each step: First, modify our model.
                    */
                    [imageCollection moveImageFileFromIndex:fromItemIndex toIndex:toItemIndex];

                    /*
                        Next, notify the CollectionView of the change we just
                        made to our model.
                    */
                    [[imageCollectionView animator] moveItemAtIndexPath:[NSIndexPath indexPathForItem:fromItemIndex inSection:[indexPath section]] toIndexPath:[NSIndexPath indexPathForItem:toItemIndex inSection:[indexPath section]]];
                    
                    // Advance to maintain moved items in their original order.
                    ++toItemIndex;
                }
            }];
            
            /*
                Walk backward through fromItemIndex values < toItemIndex, to
                keep our "from" and "to" indexes valid as we go, moving items
                one at a time.
            */
            __block NSInteger adjustedToItemIndex = indexPath.item - 1;
            [indexPathsOfItemsBeingDragged enumerateIndexPathsWithOptions:NSEnumerationReverse  usingBlock:^(NSIndexPath *fromIndexPath, BOOL *stop) {
                NSInteger fromItemIndex = [fromIndexPath item];
                if (fromItemIndex < adjustedToItemIndex) {

                    /*
                        For each step: First, modify our model.
                    */
                    [imageCollection moveImageFileFromIndex:fromItemIndex toIndex:adjustedToItemIndex];

                    /*
                        Next, notify the CollectionView of the change we just
                        made to our model.
                    */
                    NSIndexPath *adjustedToIndexPath = [NSIndexPath indexPathForItem:adjustedToItemIndex inSection:[indexPath section]];
                    [imageCollectionView.animator moveItemAtIndexPath:[NSIndexPath indexPathForItem:fromItemIndex inSection:indexPath.section] toIndexPath:adjustedToIndexPath];

                    // Retreat to maintain moved items in their original order.
                    --adjustedToItemIndex;
                }
            }];
     
            // We did it!
            result = YES;
        }
        
    } else {
        
        // Items are being dragged from elsewhere into our CollectionView.
        
        /*
            Examine the items to be dropped, as provided by the draggingInfo
            object.  Accumulate the URLs among them into a "droppedObjects"
            array.
        */
        NSMutableArray *droppedObjects = [NSMutableArray array];
        [draggingInfo enumerateDraggingItemsWithOptions:0 forView:collectionView classes:@[[NSURL class]] searchOptions:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSPasteboardURLReadingFileURLsOnlyKey, nil] usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
            
            NSURL *url = draggingItem.item;
            if ([url isKindOfClass:[NSURL class]]) {
                [droppedObjects addObject:url];
            }
        }];
        
        /*
            For each dropped URL:

            1. Create a corresponding AAPLImageFile.
            2. Insert the AAPLImageFile at the designated point in our
               imageCollection.
            3. Notify our CollectionView of the insertion.

            We check first whether the colleciton already contains an ImageFile
            with the given URL, and disallow duplicates.
        */
        NSInteger insertionIndex = indexPath.item;
        NSMutableArray *errors = [[NSMutableArray alloc] init];
        for (NSURL *url in droppedObjects) {
            AAPLImageFile *imageFile = [imageCollection imageFileForURL:url];
            if (imageFile == nil) {
                
                /*
                    Copy the image file from the source URL into our
                    imageCollection's folder.
                */
                NSURL *targetURL = [imageCollection.rootURL URLByAppendingPathComponent:url.lastPathComponent isDirectory:NO];
                NSError *error;
                if ([[NSFileManager defaultManager] copyItemAtURL:url toURL:targetURL error:&error]) {

                    /*
                        Now create and insert an ImageFile that references the
                        targetURL we copied to.
                    */
                    imageFile = [[AAPLImageFile alloc] initWithURL:targetURL];
                    if (imageFile) {
                        /*
                         For each item: First, modify our model.
                         */
                        [imageCollection insertImageFile:imageFile atIndex:insertionIndex];
                        
                        /*
                         Next, notify the CollectionView of the change we just
                         made to our model.
                         */
                        [collectionView.animator insertItemsAtIndexPaths:[NSSet<NSIndexPath *> setWithCollectionViewIndexPath:indexPath]];
                        
                        // We succeeded in accepting at least one item.
                        result = YES;
                    }
                } else {
                    /*
                        Copy failed.  Remember the error, and notify the user of
                        just the first failure, instead of pestering them about
                        each of potentially several failures.
                    */
                    if (error) {
                        [errors addObject:error];
                    }
                }
            }
        }
        
        if (errors.count > 0) {
            [imageCollectionView presentError:errors[0] modalForWindow:imageCollectionView.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
        }
    }

    // Resume normal KVO handling.
    [self resumeAutoUpdateResponse];

    // Return indicating success or failure.
    return result;
}


#pragma mark Teardown

- (void)windowWillClose:(NSNotification *)notification {
    [imageCollection stopWatchingFolder]; // Break retain cycle, allowing teardown.
    [self stopObservingImageCollection];
    [imageCollectionView removeObserver:self forKeyPath:selectionIndexPathsKey];
}

@end

@implementation AAPLBrowserWindowController (Internals)

- (void)showStatus:(NSString *)statusMessage {
    statusTextField.stringValue = statusMessage;
}

- (void)startObservingImageCollection {
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
    if (groupByTag) {
        [imageCollection addObserver:self forKeyPath:tagsKey options:0 context:NULL];
        for (AAPLTag *tag in imageCollection.tags) {
            [tag addObserver:self forKeyPath:imageFilesKey options:0 context:NULL];
        }
    } else {
        [imageCollection addObserver:self forKeyPath:imageFilesKey options:0 context:NULL];
    }
}

- (void)stopObservingImageCollection {
    if (groupByTag) {
        [imageCollection removeObserver:self forKeyPath:tagsKey];
        for (AAPLTag *tag in imageCollection.tags) {
            [tag removeObserver:self forKeyPath:imageFilesKey];
        }
    } else {
        [imageCollection removeObserver:self forKeyPath:imageFilesKey];
    }
}

- (void)handleImageFilesInsertedAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    NSAnimationContext.currentContext.duration = 0.25;
    [self.imageCollectionView.animator insertItemsAtIndexPaths:indexPaths];
}

- (void)handleImageFilesRemovedAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    NSAnimationContext.currentContext.duration = 0.25;
    [self.imageCollectionView.animator deleteItemsAtIndexPaths:indexPaths];
}

- (void)handleTagsInsertedInCollectionAtIndexes:(NSIndexSet *)indexes {
    NSAnimationContext.currentContext.duration = 0.25;
    [self.imageCollectionView.animator insertSections:indexes];
}

- (void)handleTagsRemovedFromCollectionAtIndexes:(NSIndexSet *)indexes {
    NSAnimationContext.currentContext.duration = 0.25;
    [self.imageCollectionView.animator deleteSections:indexes];
}

@end

static NSString *StringFromCollectionViewDropOperation(NSCollectionViewDropOperation dropOperation) {
    switch (dropOperation) {
        case NSCollectionViewDropBefore:
            return @"before";
            
        case NSCollectionViewDropOn:
            return @"on";
            
        default:
            return @"?";
    }
}

static NSString *StringFromCollectionViewIndexPath(NSIndexPath *indexPath) {
    if (indexPath && indexPath.length == 2) {
        return [NSString stringWithFormat:@"(%ld,%ld)", (long)(indexPath.section), (long)(indexPath.item)];
    } else {
        return @"(nil)";
    }
}
