//
//  CoverFetcher.m
//  LastCover
//
//  Created by Meleshkin Valery on 23.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import "CoverFetcher.h"
#import "DefaultsDefines.h"

BOOL IsInSameAlbum(iTunesTrack *t1, iTunesTrack *t2) {
	if ([t1.artist isEqual:t2.artist])
		if ([t1.album isEqual:t2.album])
			return YES;
	return NO;
}

NSImage * DownloadCover(NSString *url) {
	if (!url || ![url hasPrefix:@"http"]) return nil;
	
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
        //NSLog(@"req:%@", reqUrl);
        NSURL *url = [NSURL URLWithString:reqUrl];
        if (!url) return nil;
        
        [NSThread sleepForTimeInterval:0.1];
        NSData *bytes = [NSData dataWithContentsOfURL:url];
        if(!bytes) return nil;
        
        NSError *err = nil;
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:bytes options:0 error:&err];
        if(err)
            NSLog(@"Error %@ occured while parsing JSON from %@", err, reqUrl);
        if(!resp) return nil;
        
        res = resp;
    }
    return res;
}

double rank(NSString *s1, NSString *s2) {
    NSUInteger score = [[s1 commonPrefixWithString:s2
                                           options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch]
                        length];
    
    if (score == s1.length || score == s2.length)
        score *= 2;
    
    NSCharacterSet *cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSSet *toks1 = [NSSet setWithArray: [s1 componentsSeparatedByCharactersInSet:cs]];
    NSSet *toks2 = [NSSet setWithArray: [s2 componentsSeparatedByCharactersInSet:cs]];
    NSMutableSet *res = [[NSMutableSet alloc] initWithSet:toks1];
    [res intersectSet:toks2];
    
    if (res.count > 0)
        score += [res.allObjects componentsJoinedByString:@""].length;
    else
        score = 0;
    
    return score;
}

NSString * CoverURLForArtistAlbumPlain(NSString *artistName, NSString *albumName) {
    if (artistName == nil || albumName == nil)
		return nil;
    
    NSString *albNameUrled = [albumName  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *artNameUrled = [artistName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];;
    NSString *methodURL = [NSString stringWithFormat:
                           @"?method=album.getInfo&artist=%@&album=%@&autocorrect1",
                           artNameUrled, albNameUrled];
    NSDictionary *albumInfo = JSONforMethod(methodURL);
    return ([albumInfo[@"album"][@"image"] lastObject])[@"#text"];
}

NSString * CoverURLForArtistAlbum(NSString *artistName, NSString *albumName) {
	if (artistName == nil || albumName == nil)
		return nil;
    
	NSString *artNameUrled = [artistName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *methodURL = [NSString stringWithFormat:
                           @"?method=artist.getTopAlbums&artist=%@&autocorrect1",
                           artNameUrled];
    NSDictionary *albumsInfo = JSONforMethod(methodURL);
    NSArray *albums = albumsInfo[@"topalbums"][@"album"];
    NSArray *ranked = [albums sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a1, NSDictionary *a2) {
        double r1 = rank(a1[@"name"], albumName);
        double r2 = rank(a2[@"name"], albumName);
        if (r1 < r2) return NSOrderedAscending;
        if (r1 > r2) return NSOrderedDescending;
        if([a1[@"name"] localizedCaseInsensitiveCompare:a2[@"name"]] == NSOrderedAscending)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    /*
    NSLog(@"%@", albumName);
    for (id r in ranked) {
        NSLog(@"%@", r[@"name"]);
    }
    NSLog(@"------------");
    */
    
    NSString *refinedAlbumName = ranked.lastObject[@"name"];
    if (rank(refinedAlbumName, albumName) > 0)
        return CoverURLForArtistAlbumPlain(artistName, refinedAlbumName);
    else
        return nil;
}

NSImage * FetchCoverForArtistAlbum(NSString *artistName, NSString *albumName) {
    NSString *urlStringR = CoverURLForArtistAlbum(artistName, albumName);
    NSString *urlStringE = CoverURLForArtistAlbumPlain(artistName, albumName);
	
    NSImage *refined = DownloadCover(urlStringR);
    NSImage *exact = DownloadCover(urlStringE);
    if (exact && refined) {
        if (refined.size.height > exact.size.height) {
            return refined;
        }
    }
    else if (exact) return exact;
	return refined;
}
