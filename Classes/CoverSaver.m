//
//  CoverSaver.m
//  LastCover
//
//  Created by Meleshkin Valeryi on 23.07.10.
//  Copyright 2010 Terem-media. All rights reserved.
//

#import <EyeTunes/EyeTunes.h>
#import "CoverSaver.h"
#import "DefaultsDefines.h"


@implementation CoverSaver

+ (void)initialize {
	NSDictionary *saverDefaults = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:SAVE_COVER_IN_PLAYING_TRACK];
	[[NSUserDefaults standardUserDefaults] registerDefaults:saverDefaults];
}

- (BOOL)isInSeparateThread {
	return YES;
}

- (BOOL)processTrack:(TrackDesc *)trackd {
	if (!trackd)
		return NO;
	
	BOOL saveForNowPlaying = [[NSUserDefaults standardUserDefaults] boolForKey:SAVE_COVER_IN_PLAYING_TRACK];
	
	//NSLog(@"%d", saveForNowPlaying);
	
	if (!trackd.newArtwork)
		return NO;

	if (([trackd.track databaseId] == [[[EyeTunes sharedInstance] currentTrack] databaseId]) && !saveForNowPlaying) {
		//NSLog(@"skip!!!!!!!");
		[self addTrackDesc:trackd];
		return NO;
	}
	
	NSArray *arts = [[NSArray alloc] initWithObjects:trackd.newArtwork, nil];
	[trackd.track setArtwork:arts];
	[arts release];
	
	NSLog(@"Saved: %@ - %@", [trackd.track album], [trackd.track name]);
	return YES;
}

@end
