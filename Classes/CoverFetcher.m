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
        //NSLog(@"req:%@", reqUrl);
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
    //if (res) NSLog(@"Fetched: %@ - %@", artistName, albumName);
	return res;
}
