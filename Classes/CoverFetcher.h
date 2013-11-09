//
//  CoverFetcher.h
//  LastCover
//
//  Created by Meleshkin Valery on 23.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ChainLink.h"


@interface CoverFetcher : ChainLink {
	TrackDesc *prevDesc;
	NSImage *prevArt;
	NSArray *prevVariants;
}

+ (NSImage *)fetchCoverForArtist:(NSString *)artistName album:(NSString *)albumName;
//+ (NSArray *)fetchCoversForAlbum:(NSString *)albumName;

@end
