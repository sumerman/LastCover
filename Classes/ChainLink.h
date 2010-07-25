//
//  ChainLink.h
//  LastCover
//
//  Created by Meleshkin Valeryi on 23.07.10.
//  Copyright 2010 Terem-media. All rights reserved.
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

@property (retain) ChainLink *nextLink;

- init;
- initWithNextLink:(ChainLink *)link;
- (void)dealloc;

- (void)addTrackDesc:(TrackDesc *)track;
- (void)addTrackDescs:(NSArray *)tracks;

- (void)processTracks;
- (BOOL)processTrack:(TrackDesc *)track; 
@end
