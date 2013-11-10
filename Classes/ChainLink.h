//
//  ChainLink.h
//  LastCover
//
//  Created by Meleshkin Valery on 23.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TrackDesc.h"

@interface ChainLink : NSObject {
	ChainLink *nextLink;
	
	BOOL done, working;
	NSThread *worker;
	
	NSLock *lock;
	NSMutableArray *unprocessedTracks;
	NSMutableArray *processedTracks;
}

@property (strong) ChainLink *nextLink;

- init;
- initWithNextLink:(ChainLink *)link;
- (void)dealloc;

- (void)addTrackDesc:(TrackDesc *)track;
- (void)addTrackDescs:(NSArray *)tracks;

- (void)processTracks;

@end
