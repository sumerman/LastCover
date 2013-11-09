//
//  CoverFetcher.m
//  LastCover
//
//  Created by Meleshkin Valery on 23.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import "CoverFetcher.h"
#import "DefaultsDefines.h"

@interface CoverFetcher ()

@property (nonatomic, retain) TrackDesc *prevDesc;
@property (nonatomic, retain) NSImage *prevArt;
@property (nonatomic, retain) NSArray *prevVariants;

@end


@implementation CoverFetcher

@synthesize prevDesc, prevArt, prevVariants;

+ (NSImage *)coverFromUrl:(NSString *)url {
	if (!url)
		return nil;
	
	NSImage *coverImg = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
	NSImageRep *repr = [[coverImg representations] objectAtIndex:0];
	[coverImg setScalesWhenResized:YES];
	[coverImg setSize:NSMakeSize([repr pixelsWide], [repr pixelsHigh])];
	
	return [coverImg autorelease];
}

+ (id)JSONforMethod:(NSString *)methodStr {
    id res = nil;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        NSString *reqUrl = [NSString stringWithFormat:@"%@/%@&api_key=%@&format=json",
                            @"http://ws.audioscrobbler.com/2.0/", methodStr, API_KEY];
        NSLog(@"req:%@", reqUrl);
        NSURL *url = [NSURL URLWithString:reqUrl];
        if (!url)
            @throw nil;
        
        NSData *bytes = [NSData dataWithContentsOfURL:url];
        if(!bytes)
            @throw nil;
        
        NSError *err = nil;
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:bytes options:0 error:&err];
        if(err)
            NSLog(@"Error %@ occured while parsing JSON from %@", err, reqUrl);
        if(!resp)
            @throw nil;
        
        res = [resp retain];
    }
    @finally {
        [pool release];
    }
    return [res autorelease];
}

+ (NSString *)coverUrlForArtist:(NSString *)artistName album:(NSString *)albumName {
	if (artistName == nil || albumName == nil) 
		return nil;
    
	// string must be coverted to url-convinent format
	NSString *artNameUrled = [artistName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *albNameUrled = [albumName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
    NSString *methodURL = [NSString stringWithFormat:
                           @"?method=album.getinfo&artist=%@&album=%@&autocorrect1",
                           artNameUrled, albNameUrled];
    NSDictionary *albumInfo = [[self class] JSONforMethod:methodURL];
    return [[[[albumInfo objectForKey: @"album"] objectForKey: @"image"] lastObject] objectForKey:@"#text"];
}

/*
+ (NSArray *)coversUrlForAlbum:(NSString *)albumName {
	if (albumName == nil)
		return nil;
	NSString *albNameUrled = [albumName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	reqUrl = [[NSString alloc] initWithFormat:
			  @"http://ws.audioscrobbler.com/2.0/?method=album.search&album=%@&api_key=%@",
	NSArray *nodes = [[xml rootElement] nodesForXPath:@"/lfm/results/albummatches/album/image[@size='extralarge']" error:&err];
}
*/

+ (NSImage *)fetchCoverForArtist:(NSString *)artistName album:(NSString *)albumName {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *imageUrlString = [[[self  class] coverUrlForArtist:artistName album:albumName] retain];
	[pool release];
	
	if (!imageUrlString) 
		return nil;
	
	NSImage *cov = [[self class] coverFromUrl:imageUrlString];
	
	[imageUrlString release];
	return cov;
}

- (BOOL)processTrack:(TrackDesc *)trackd {
	if (!trackd)
		return NO;
	
	NSImage *art = nil;
	
	if ([prevDesc isInSameAlbumWith:trackd])
		art = self.prevArt;
	
	art = art ? art : [[self class] fetchCoverForArtist:[trackd.track artist] album:[trackd.track album]];
	self.prevArt = art;
	self.prevDesc = trackd;
	
    trackd.theNewArtwork = art;
	
	NSLog(@"Fetched: %@ - %@", [trackd.track album], [trackd.track name]);
	return YES;
}

- (BOOL)isInSeparateThread {
	return YES;
}

@end
