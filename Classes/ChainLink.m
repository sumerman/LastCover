//
//  ChainLink.m
//  LastCover
//
//  Created by Meleshkin Valery on 23.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import "ChainLink.h"

#pragma mark Private interface

@interface ChainLink ()

- (void)mainRoutine:(id)obj;
- (BOOL)isInSeparateThread;

- (BOOL)processTrack:(TrackDesc *)track; 

@property (assign, getter=isDone) BOOL done;
@property (assign, getter=isWorking) BOOL working;

@end


#pragma mark -
#pragma mark Implementation

@implementation ChainLink

#pragma mark -
#pragma mark Properties

@synthesize nextLink;
@synthesize done, working;

#pragma mark -
#pragma mark Class life-cycle 

- init {
	return [self initWithNextLink: nil];
}

- initWithNextLink:(ChainLink *)link {
	if (!(self = [super init])) return nil;
	
    for (int32_t i = 0; i < IN_N; ++i) {
        incomingQueues[i] = [[NSMutableArray alloc] init];
    }
    currentIncoming = 0;
	
	self.nextLink = link;
	
	self.done = NO;
	self.working = NO;
	
	if ([self isInSeparateThread]) {
		worker = [[NSThread alloc] initWithTarget:self selector:@selector(mainRoutine:) object:nil];
		[worker start];
	}
	
	return self;
}

- (void)dealloc {
	self.done = YES;
	while ([self isWorking]) {
		// wait for the worker
	}
}

- (__weak NSMutableArray *)incomingQueue {
    return incomingQueues[currentIncoming];
}

- (int32_t)swapIncoming {
    BOOL res = false;
    int32_t prev = 0;
    while (res == false) {
        prev = currentIncoming;
        int32_t newv = (prev + 1) % IN_N;
        res = OSAtomicCompareAndSwap32Barrier(prev, newv, &currentIncoming);
    }
    return prev;
}

#pragma mark -
#pragma mark Worker thread stuff

- (BOOL)isInSeparateThread {
	return NO;
}

- (void)mainRoutine:(id)obj {
	self.working = YES;
	@autoreleasepool {
		while (![self isDone]) {
			[self processTracks];
			[NSThread sleepForTimeInterval:0.1];
		}
	}
	self.working = NO;
}

#pragma mark -
#pragma mark Pipeline routines

- (void)addTrackDesc:(TrackDesc *)track {
	if (!track)
		return;
	
    NSMutableArray *q = [self incomingQueue];
    @synchronized(q) {
        [q addObject:@[track]];
    }
}

- (void)addTrackDescs:(NSArray *)tracks {
	if (!tracks)
		return;

    NSMutableArray *q = [self incomingQueue];
    @synchronized(q) {
        [q addObject:tracks];
    }
}

- (void)reportFailure:(TrackDesc *)trackd {
    NSUserNotification *notif = [[NSUserNotification alloc] init];
    notif.title = @"Cover fetch failed";
    notif.informativeText = [[NSString alloc] initWithFormat:@"%@ — %@", trackd.track.artist, trackd.track.album];
    notif.hasActionButton = true;
    notif.actionButtonTitle = @"Retry";
    notif.userInfo = @{@"artist": trackd.track.artist,
                       @"album": trackd.track.album};
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notif];
}

- (void)processTracks {
    if ([[self incomingQueue] count] == 0)
        return;
    
    int32_t prevq = [self swapIncoming];
    NSMutableArray *q_to_process = incomingQueues[prevq];
    NSMutableArray *processedTracks = [[NSMutableArray alloc] init];
	@autoreleasepool {
        for (NSArray *batch in q_to_process) {
            for (TrackDesc *curTrack in batch) {
                if ([self processTrack:curTrack])
                    [processedTracks addObject:curTrack];
                else
                    [self reportFailure:curTrack];
            }
        }
    }
    // push all processed to the nextLink
    if (nextLink)
        [nextLink addTrackDescs:processedTracks];
    [q_to_process removeAllObjects];
}

- (BOOL)processTrack:(TrackDesc *)track {
	NSLog(@"%@", track);
	// do nothing, should be redefined in a subclass
	return YES;
}

@end
