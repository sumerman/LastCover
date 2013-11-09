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
	[super init];
	
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
	[worker release];
	
	self.nextLink = nil;
	
	[unprocessedTracks release];
	[processedTracks release];
	[lock release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Worker thread stuff

- (BOOL)isInSeparateThread {
	return NO;
}

- (void)mainRoutine:(id)obj {
	self.working = YES;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while (![self isDone]) {
		[self processTracks];
		[NSThread sleepForTimeInterval:0.1];
	}
	[pool release];
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

- (void)processTracks {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// enumerate through unproc tracks, 
	// call processTrack for each, 
	// and then add it to proccessed
	TrackDesc *curTrack = nil;
	while ([unprocessedTracks count]) {
		[lock lock];
		
		curTrack = [[unprocessedTracks objectAtIndex:0] retain];
		[unprocessedTracks removeObjectAtIndex:0];
		
		[lock unlock];
		
		if ([self processTrack:curTrack])
			[processedTracks addObject:curTrack];
		[curTrack release];
		
		// push all processed to the nextLink
		if (nextLink) {
			[nextLink addTrackDescs:processedTracks];
			[processedTracks removeAllObjects];
		}
		
	}
	[pool release];
}

- (BOOL)processTrack:(TrackDesc *)track {
	NSLog(@"%@", track);
	// do nothing, should be redefined in a subclass
	return YES;
}

@end
