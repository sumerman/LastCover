//
//  CoverFetcher.h
//  LastCover
//
//  Created by Meleshkin Valery on 23.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"

typedef void (^FetchFail) (NSArray *failedTracks);

BOOL IsInSameAlbum(iTunesTrack *t1, iTunesTrack *t2);
NSImage * FetchCoverForArtistAlbum(NSString *artistName, NSString *albumName);
