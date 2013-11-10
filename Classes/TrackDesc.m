//
//  TrackDesc.m
//  LastCover
//
//  Created by Meleshkin Valery on 11.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import "TrackDesc.h"

@implementation TrackDesc

@synthesize theNewArtwork, theNewArtworkVariants;
@dynamic track;

- init {
	return [self initWithTrack:nil];
}
- initWithTrack:(iTunesTrack *)aTrack {
	if (!(self = [super init])) return nil;
	
	self.theNewArtwork = nil;
	self.theNewArtworkVariants = nil;
	[self setTrack:aTrack];
	
	return self;
}

+ trackDescWithTrack:(iTunesTrack *)aTrack {
	return [[[self class] alloc] initWithTrack:aTrack];
}

- (void)setTrack:(iTunesTrack *)aTrack {
	if (track)
		return;
	
	track = aTrack;
}

- (iTunesTrack *)track {
	return track;
}


- (void)forwardInvocation:(NSInvocation *)invoc {
	SEL sel = [invoc selector];
	if ([track respondsToSelector:sel]) 
		[invoc invokeWithTarget:track];
	else 
		[self doesNotRecognizeSelector:sel];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"TrackDesc: name:%@ album:%@\nartwork:%@\nnewArtwork%@\nnewArtworkVariants:%@", 
			[track name], [track album], [track artworks], self.theNewArtwork, self.theNewArtworkVariants];
}

- (BOOL)isInSameAlbumWith:(TrackDesc *)trackd {
	if ([[self.track artist] isEqual:[trackd.track artist]])
		if ([[self.track album] isEqual:[trackd.track album]])
			return YES;
	return NO;
}

@end
