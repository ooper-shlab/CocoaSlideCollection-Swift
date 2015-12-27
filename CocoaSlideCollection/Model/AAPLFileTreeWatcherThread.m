/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the "FileTreeWatcherThread" class implementation.
*/

#import "AAPLFileTreeWatcherThread.h"

static void AAPLFileTreeWatcherEventStreamCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]);

@implementation AAPLFileTreeWatcherThread

- initWithPath:(NSString *)pathToWatch changeHandler:(void (^)(void))changeHandler {
    NSParameterAssert(pathToWatch);
    NSParameterAssert(changeHandler);
    self = [self init];
    if (self) {
        [self setName:@"AAPLFileTreeWatcherThread"];
        paths = @[pathToWatch];
        @synchronized(self) {
            handler = [changeHandler copy];
        }
    }
    return self;
}

- (void)invokeChangeHandler {
    @synchronized(self) {
        if (handler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:handler];
        }
    }
}

- (void)detachChangeHandler {
    @synchronized(self) {
        handler = nil;
    }
}

- (void)main {
    @autoreleasepool {
        
        // Create our fsEventStream.
        FSEventStreamContext context;
        context.version = 0;
        context.info = (__bridge void *)self;
        context.retain = NULL;
        context.release = NULL;
        context.copyDescription = NULL;
        fsEventStream = FSEventStreamCreate(kCFAllocatorDefault, AAPLFileTreeWatcherEventStreamCallback, &context, CFBridgingRetain(paths), kFSEventStreamEventIdSinceNow, 1.0, kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagWatchRoot | kFSEventStreamCreateFlagIgnoreSelf);
        if (fsEventStream != NULL) {
            
            // Schedule the fsEventStream on our thread's run loop.
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            CFRunLoopRef cfRunLoop = [runLoop getCFRunLoop];
            FSEventStreamScheduleWithRunLoop(fsEventStream, cfRunLoop, kCFRunLoopCommonModes);
            
            // Open the faucet.
            FSEventStreamStart(fsEventStream);
            
            // Run until we're asked to stop.
            while (![self isCancelled]) {
                [runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
            }
            
            // Shut off the faucet.
            FSEventStreamStop(fsEventStream);
            
            // Unschedule the fsEventStream on our thread's run loop.
            FSEventStreamUnscheduleFromRunLoop(fsEventStream, cfRunLoop, kCFRunLoopCommonModes);

            // Invalidate and release fsEventStream.
            FSEventStreamInvalidate(fsEventStream);
            FSEventStreamRelease(fsEventStream);
            fsEventStream = NULL;
        }
    }
}

@end

static void AAPLFileTreeWatcherEventStreamCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
    if (numEvents > 0) {
        AAPLFileTreeWatcherThread *thread = (__bridge AAPLFileTreeWatcherThread *)clientCallBackInfo;

        [thread invokeChangeHandler];
    }
}
