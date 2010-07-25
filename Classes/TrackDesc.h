//
//  TrackDesc.h
//  LastCover
//
//  Created by Meleshkin Valeryi on 11.07.10.
//  Copyright 2010 Terem-media. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <EyeTunes/EyeTunes.h>

@interface TrackDesc : NSObject
{
	ETTrack *track;
	NSImage *newArtwork;
	NSArray *newArtworkVariants;
}

@property (copy) NSImage *newArtwork;
@property (copy) NSArray *newArtworkVariants;
@property (retain) ETTrack *track;

- init;
- initWithTrack:(ETTrack *)aTrack;
+ trackDescWithTrack:(ETTrack *)aTrack;
- (void)dealloc;

// works only if track is still not assigned
- (void)setTrack:(ETTrack *)aTrack;
- (ETTrack *)track;

@end

