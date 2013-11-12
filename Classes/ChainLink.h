//
//  ChainLink.h
//  LastCover
//
//  Created by Meleshkin Valery on 23.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TrackDesc.h"

#define IN_N 2

@interface ChainLink : NSObject {
	ChainLink *nextLink;
	
	BOOL done, working;
	NSThread *worker;
	
    volatile int32_t currentIncoming;
	NSMutableArray *incomingQueues[IN_N];
}

@property (strong) ChainLink *nextLink;

- init;
- initWithNextLink:(ChainLink *)link;
- (void)dealloc;

- (void)addTrackDesc:(TrackDesc *)track;
- (void)addTrackDescs:(NSArray *)tracks;

- (void)processTracks;

@end
