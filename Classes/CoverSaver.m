//
//  CoverSaver.m
//  LastCover
//
//  Created by Meleshkin Valery on 23.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import "iTunes.h"
#import "CoverSaver.h"
#import "DefaultsDefines.h"
#import "LastCoverAppDelegate.h"

@implementation CoverSaver

+ (void)initialize {
	NSDictionary *saverDefaults = @{SAVE_COVER_IN_PLAYING_TRACK: @YES};
	[[NSUserDefaults standardUserDefaults] registerDefaults:saverDefaults];
}

- (BOOL)isInSeparateThread {
	return YES;
}

- (BOOL)processTrack:(TrackDesc *)trackd {
	if (!trackd)
		return NO;
	
	BOOL saveForNowPlaying = [[NSUserDefaults standardUserDefaults] boolForKey:SAVE_COVER_IN_PLAYING_TRACK];
	
	if (!trackd.theNewArtwork)
		return NO;
    
    LastCoverAppDelegate *delegate = [[NSApplication sharedApplication] delegate];
    iTunesTrack *curTrk = [[delegate itunes] currentTrack];
	if (([trackd.track.persistentID isEqualToString:curTrk.persistentID]) && !saveForNowPlaying) {
		//NSLog(@"skipping");
		[self addTrackDesc:trackd];
		return NO;
	}
    
    NSUInteger artid = trackd.track.artworks.count;
    iTunesArtwork *aw = (trackd.track.artworks)[artid];
    aw.data = trackd.theNewArtwork;
	NSLog(@"Saved: %@ - %@", [trackd.track album], [trackd.track name]);
	return YES;
}

@end
