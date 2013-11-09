//
//  TrackDesc.h
//  LastCover
//
//  Created by Meleshkin Valery on 11.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"

@interface TrackDesc : NSObject
{
	iTunesTrack *track;
	NSImage *theNewArtwork;
	NSArray *theNewArtworkVariants;
}

@property (copy) NSImage *theNewArtwork;
@property (copy) NSArray *theNewArtworkVariants;
@property (retain) iTunesTrack *track;

- init;
- initWithTrack:(iTunesTrack *)aTrack;
+ trackDescWithTrack:(iTunesTrack *)aTrack;
- (void)dealloc;

// works only if iTunesTrack is still not assigned
- (void)setTrack:(iTunesTrack *)aTrack;
- (iTunesTrack *)track;

- (BOOL)isInSameAlbumWith:(TrackDesc *)desc;

@end

