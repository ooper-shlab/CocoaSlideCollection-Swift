/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "FileTreeWatcherThread" class declaration.
*/

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

@interface AAPLFileTreeWatcherThread : NSThread
{
    NSArray *paths;                 // array of paths we're watching (as NSStrings)
    void (^handler)(void);          // the block to invoke when we sense a change
    FSEventStreamRef fsEventStream; // the FSEventStream that's informing us of changes
}

/*
    Creates a new AAPLFileTreeWatcherThread that monitors the file subtree
    specified by the given path, and invokes the given "changeHandler" block
    each time a change in the file subtree is detected.
 
    Send -start to the returned instance to start watching the file system.
    Send -cancel to stop.
    (AAPLFileTreeWatcherThread inherits these API methods from NSThread.)
*/
- initWithPath:(NSString *)pathToWatch changeHandler:(void (^)(void))changeHandler;

/*
    Invoked by AAPLFileTreeWatcherThread to schedule main-thread invocation of
    its changeHandler.
*/
- (void)invokeChangeHandler;

/*
    Invoke this to zero out the thread's "changeHandler" pointer when things it
    operates on are about to go away.  (Sending -cancel to the thread isn't
    sufficient to ensure that it won't invoke its "changeHandler" one more
    time.)
*/
- (void)detachChangeHandler;

@end
