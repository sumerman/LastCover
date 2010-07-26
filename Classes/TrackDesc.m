//
//  TrackDesc.m
//  LastCover
//
//  Created by Meleshkin Valeryi on 11.07.10.
//  Copyright 2010 Terem-media. All rights reserved.
//

#import "TrackDesc.h"

@implementation TrackDesc

@synthesize newArtwork, newArtworkVariants;
@dynamic track;

- init {
	return [self initWithTrack:nil];
}
- initWithTrack:(ETTrack *)aTrack {
	[super init];
	
	self.newArtwork = nil;
	self.newArtworkVariants = nil;
	[self setTrack:aTrack];
	
	return self;
}

+ trackDescWithTrack:(ETTrack *)aTrack {
	return [[[[self class] alloc] initWithTrack:aTrack] autorelease];
}

- (void)setTrack:(ETTrack *)aTrack {
	if (track)
		return;
	
	[track release];
	track = [aTrack retain];
}

- (ETTrack *)track {
	return track;
}

- (void)dealloc {
	self.newArtwork = nil;
	self.newArtworkVariants = nil;
	[track release];
	
	[super dealloc];
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
			[track name], [track album], [track artwork], self.newArtwork, self.newArtworkVariants];
}

- (BOOL)isInSameAlbumWith:(TrackDesc *)trackd {
	if ([[self.track artist] isEqual:[trackd.track artist]])
		if ([[self.track album] isEqual:[trackd.track album]])
			return YES;
	return NO;
}

@end
