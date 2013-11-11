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
	
	lock = [[NSLock alloc] init];
	processedTracks = [[NSMutableArray alloc] init];
	unprocessedTracks = [[NSMutableArray alloc] init];
	
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
	
	[lock lock];
	[unprocessedTracks addObject:track];
	[lock unlock];
}

- (void)addTrackDescs:(NSArray *)tracks {
	if (!tracks)
		return;
	
	for (id track in tracks) {
		NSAssert([track isMemberOfClass:[TrackDesc class]], @"track isn't kind of TrackDesc class");
	}
	
	[lock lock];
	[unprocessedTracks addObjectsFromArray:tracks];
	[lock unlock];
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
	@autoreleasepool {
        // enumerate through unproc tracks,
        // call processTrack for each,
        // and then add it to proccessed
		TrackDesc *curTrack = nil;
		while ([unprocessedTracks count]) {
			[lock lock];
			
			curTrack = unprocessedTracks[0];
			[unprocessedTracks removeObjectAtIndex:0];
			
			[lock unlock];
			
			if ([self processTrack:curTrack])
				[processedTracks addObject:curTrack];
            else
                [self reportFailure:curTrack];
			
			// push all processed to the nextLink
			if (nextLink) {
				[nextLink addTrackDescs:processedTracks];
				[processedTracks removeAllObjects];
			}
			
		}
	}
}

- (BOOL)processTrack:(TrackDesc *)track {
	NSLog(@"%@", track);
	// do nothing, should be redefined in a subclass
	return YES;
}

@end
