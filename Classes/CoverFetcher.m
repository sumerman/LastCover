//
//  CoverFetcher.m
//  LastCover
//
//  Created by Meleshkin Valeryi on 23.07.10.
//  Copyright 2010 Terem-media. All rights reserved.
//

#import "CoverFetcher.h"

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

+ (NSString *)coverUrlForArtist:(NSString *)artistName album:(NSString *)albumName {
	if (artistName == nil || albumName == nil) 
		return nil;
	
	// Forming request for last fm
	NSString *reqUrl = nil;
	// string must be coverted to url-convinent format
	NSString *artNameUrled = [artistName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *albNameUrled = [albumName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	reqUrl = [[NSString alloc] initWithFormat:
			  @"http://ws.audioscrobbler.com/2.0/?method=album.getinfo&artist=%@&album=%@&api_key=b25b959554ed76058ac220b7b2e0a026", 
			  artNameUrled, albNameUrled];
	NSLog(@"req:%@", reqUrl);
	
	NSURL *url = [NSURL URLWithString:reqUrl];
	[reqUrl release];
	if (!url)
		return nil;
	
	// obtain xml-response
	NSError *err = nil;
	NSXMLDocument *xml = [[NSXMLDocument alloc] initWithContentsOfURL:url 
															  options:NSXMLNodePreserveWhitespace 
																error:&err];
	if (!xml) 
		return nil;
	//NSLog(@"XML resp: %@", xml);
	
	// parse it and find urls of images
	NSArray *nodes = [[xml rootElement] nodesForXPath:@"/lfm/album/image" error:&err];
	[xml release];
	
	if (!nodes) 
		return nil;
	if ([nodes count] < 1) 
		return nil;
	
	// a larges art also is a last one into the seq of <image ...> tags
	NSString *imageUrlString = [[nodes lastObject] stringValue];
	
	return imageUrlString;
}

+ (NSArray *)coversUrlForAlbum:(NSString *)albumName {
	if (albumName == nil) 
		return nil;
	
	// Forming request for last fm
	NSString *reqUrl = nil;
	// string must be coverted to url-convinent format
	NSString *albNameUrled = [albumName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	reqUrl = [[NSString alloc] initWithFormat:
			  @"http://ws.audioscrobbler.com/2.0/?method=album.search&album=%@&api_key=b25b959554ed76058ac220b7b2e0a026", 
			  albNameUrled];
	NSLog(@"search req:%@", reqUrl);
	
	NSURL *url = [NSURL URLWithString:reqUrl];
	[reqUrl release];
	if (!url)
		return nil;
	
	// obtain xml-response
	NSError *err = nil;
	NSXMLDocument *xml = [[NSXMLDocument alloc] initWithContentsOfURL:url 
															  options:NSXMLNodePreserveWhitespace 
																error:&err];
	if (!xml) 
		return nil;
	//NSLog(@"XML resp: %@", xml);
	
	// parse it and find urls of images
	NSArray *nodes = [[xml rootElement] nodesForXPath:@"/lfm/results/albummatches/album/image[@size='extralarge']" error:&err];
	[xml release];
	
	if (!nodes) 
		return nil;
	if ([nodes count] < 1) 
		return nil;
	
	//NSLog(@"Nodes: %@", nodes);
	
	NSMutableArray *urls = [NSMutableArray arrayWithCapacity:[nodes count]];
	NSString *covUrl = nil;
	
	for (NSXMLNode *node in nodes) {
		covUrl = [node stringValue];
		
		if (covUrl && [covUrl length] > 0)
			[urls addObject:covUrl];
	}
	
	return urls;
}

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

+ (NSArray *)fetchCoversForAlbum:(NSString *)albumName {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *urls = [[[self class] coversUrlForAlbum:albumName] retain];
	[pool release];
	
	if (!urls)
		return nil;
	
	NSMutableArray *covs = [NSMutableArray arrayWithCapacity:[urls count]];
	NSImage *cover = nil;
	
	for (NSString *covUrl in urls) {
		if (!covUrl)
			continue;
		
		cover = [[self class] coverFromUrl:covUrl];
		if (!cover)
			continue;
		
		[covs addObject:cover];
	}
	
	[urls release];
	return covs;
}

- (BOOL)processTrack:(TrackDesc *)trackd {
	if (!trackd)
		return NO;
	
	NSImage *art = nil;
	NSArray *variants = nil;
	
	if ([[prevDesc.track artist] isEqual:[trackd.track artist]])
		if ([[prevDesc.track album] isEqual:[trackd.track album]]) {
			art = self.prevArt;
			variants = self.prevVariants;
		}
	
	art = art ? art : [[self class] fetchCoverForArtist:[trackd.track artist] album:[trackd.track album]];
	self.prevArt = art;
	self.prevDesc = trackd;
	
	if (!art && !variants) {			
		// search variants
		NSArray *variants = [[self class] fetchCoversForAlbum:[trackd.track album]];
		NSLog(@"Variants: %@", variants);
		self.prevVariants = variants;
	}
	
	if ([[trackd.track artwork] count] > 0)
		trackd.newArtworkVariants = [NSArray arrayWithObject:art];
	else { 
		trackd.newArtwork = art;
		trackd.newArtworkVariants = variants;
	}
	
	NSLog(@"Fetched: %@ - %@", [trackd.track album], [trackd.track name]);
	return YES;
}

- (BOOL)isInSeparateThread {
	return YES;
}

@end
