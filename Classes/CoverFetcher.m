//
//  CoverFetcher.m
//  LastCover
//
//  Created by Meleshkin Valery on 23.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import "CoverFetcher.h"
#import "DefaultsDefines.h"
#import "LastCoverAppDelegate.h"

BOOL IsInSameAlbum(iTunesTrack *t1, iTunesTrack *t2) {
	if ([t1.artist isEqual:t2.artist])
		if ([t1.album isEqual:t2.album])
			return YES;
	return NO;
}

NSImage * DownloadCover(NSString *url) {
	if (!url)
		return nil;
	
	NSImage *coverImg = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
	NSImageRep *repr = [coverImg representations][0];
	[coverImg setScalesWhenResized:YES];
	[coverImg setSize:NSMakeSize([repr pixelsWide], [repr pixelsHigh])];
	
	return coverImg;
}

id JSONforMethod(NSString *methodStr) {
    id res = nil;
    @autoreleasepool {
        NSString *reqUrl = [NSString stringWithFormat:@"%@/%@&api_key=%@&format=json",
                            @"http://ws.audioscrobbler.com/2.0/", methodStr, API_KEY];
        NSLog(@"req:%@", reqUrl);
        NSURL *url = [NSURL URLWithString:reqUrl];
        if (!url)
            return nil;
        
        NSData *bytes = [NSData dataWithContentsOfURL:url];
        if(!bytes)
            return nil;
        
        NSError *err = nil;
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:bytes options:0 error:&err];
        if(err)
            NSLog(@"Error %@ occured while parsing JSON from %@", err, reqUrl);
        if(!resp)
            return nil;
        
        res = resp;
    }
    return res;
}

NSString * CoverURLForArtistAlbum(NSString *artistName, NSString *albumName) {
	if (artistName == nil || albumName == nil)
		return nil;
    
	// names should be url-encoded
	NSString *artNameUrled = [artistName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *albNameUrled = [albumName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
    NSString *methodURL = [NSString stringWithFormat:
                           @"?method=album.getinfo&artist=%@&album=%@&autocorrect1",
                           artNameUrled, albNameUrled];
    NSDictionary *albumInfo = JSONforMethod(methodURL);
    return [albumInfo[@"album"][@"image"] lastObject][@"#text"];
}

NSImage * FetchCoverForArtistAlbum(NSString *artistName, NSString *albumName) {
    NSString *imageUrlString = CoverURLForArtistAlbum(artistName, albumName);
	
	if (!imageUrlString)
		return nil;
	
    NSImage *res = DownloadCover(imageUrlString);
    if (res)
        NSLog(@"Fetched: %@ - %@", artistName, albumName);
	return res;
}

void SaveCovers(NSArray *batch, NSImage *art) {
    NSCAssert(batch && art, @"Args must be valid objects");
    
    BOOL saveForNowPlaying = [[NSUserDefaults standardUserDefaults] boolForKey:SAVE_COVER_IN_PLAYING_TRACK];
    id delegate = [[NSApplication sharedApplication] delegate];
    
    NSMutableArray *delayed = [[NSMutableArray alloc] init];
    double delayInSeconds = 0.0;
    
    for (iTunesTrack *track in batch) {
        iTunesTrack *curTrk = [[delegate itunes] currentTrack];
        if (([track.persistentID isEqualToString:curTrk.persistentID]) && !saveForNowPlaying) {
            delayInSeconds = track.duration;
            [delayed addObject:track];
            continue;
        }
        
        NSUInteger artid = track.artworks.count;
        iTunesArtwork *aw = (track.artworks)[artid];
        aw.data = art;
        NSLog(@"Saved: %@ — %@ — %@", track.artist, track.album, track.name);
    }
    
    if ([delayed count]) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_current_queue(), ^(void){
            SaveCovers(delayed, art);
        });
    }
}

typedef NSImage * (^FetchCont) ();

void DoDispatch(FetchCont cont, NSArray *batch, FetchFail onfail) {
    if (!batch || !cont) return;
    
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(q, ^{
        NSImage *art = cont();
        if(art) SaveCovers(batch, art);
        else dispatch_async(dispatch_get_main_queue(), ^{ onfail(batch); });
    });
}

void FetchBatch(NSArray *tracks, FetchFail onfail) {
    iTunesTrack *prevTrack = nil;
    FetchCont cont = nil;
    NSMutableArray *albumBatch = nil;
    for (iTunesTrack *track in tracks) {
        if (!IsInSameAlbum(prevTrack, track)) {
            DoDispatch(cont, albumBatch, onfail);
            albumBatch = [[NSMutableArray alloc] init];
            cont = ^NSImage *() {
                return FetchCoverForArtistAlbum(track.artist, track.album);
            };
        }
        [albumBatch addObject:track];
        prevTrack = track;
        NSLog(@"Added: %@ — %@ — %@", track.artist, track.album, track.name);
    }
    DoDispatch(cont, albumBatch, onfail);
}