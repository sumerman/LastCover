//
//  LastCoverAppDelegate.m
//  LastCover
//
//  Created by Meleshkin Valeryi on 08.07.10.
//  Copyright 2010 Terem-media. All rights reserved.
//

#import "LastCoverAppDelegate.h"
#import "DefaultsDefines.h"

@implementation LastCoverAppDelegate

@synthesize window, artName, albName, trkName, sbarMenu, sbarShowConflicts, sbarIcon, sbarIconAlert;

+ (void)initialize {
	NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AUTO_FETCH_CURRENT];
	[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
}

#pragma mark -
#pragma mark Application Lifecycle


#define LOAD_ICON(name) {\
	NSString *sbarImgPath = [[NSBundle mainBundle] pathForResource:@#name ofType:@"png"]; \
	NSImage *sbarImg = [[NSImage alloc] initWithContentsOfFile:sbarImgPath]; \
	[sbarImg setSize:NSMakeSize(20.0, 20.0)]; \
	self.name = sbarImg; \
	[sbarImg release]; \
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	eyeTunes = [[EyeTunes sharedInstance] retain];
	
	LOAD_ICON(sbarIcon);
	LOAD_ICON(sbarIconAlert);
	
	// status bar menu building 
	sbarItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	[sbarItem setMenu:sbarMenu];
	[sbarItem setImage:self.sbarIcon];
	[sbarItem setHighlightMode:YES];
	
	// subscribe to application-terminated notifications
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self 
														   selector:@selector(applicationClosed:)
															   name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	
	// schedule timer for periodically updates
	updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 
												   target:self 
												 selector:@selector(updateTimerFired:) 
												 userInfo:nil 
												  repeats:YES];
	
	coverSaver = [[CoverSaver alloc] init];
	coverFetcher = [[CoverFetcher alloc] initWithNextLink:coverSaver];
}

#undef LOAD_ICON

- (void) dealloc
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[coverFetcher release];
	[coverSaver release];
	
	[updateTimer invalidate];
	[sbarItem release];
	[eyeTunes release];
	[sbarMenu release];
	[sbarIcon release];
	[sbarIconAlert release];
	[window release];
	[super dealloc];
}

- (void)setAlerted:(BOOL)alerted {
	if (alerted)
		[sbarItem setImage:self.sbarIconAlert];
	else
		[sbarItem setImage:self.sbarIcon];
	[sbarShowConflicts setEnabled:alerted];
}

- (BOOL)isAlerted {
	return [sbarShowConflicts isEnabled];
}

#pragma mark -
#pragma mark Events

- (IBAction)showCoverWindow:(id)sender {
	NSLog(@"show!");
	[window makeKeyAndOrderFront:self];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)applicationClosed:(NSNotification *)notif {
	NSString *bundleId = [[notif userInfo] objectForKey:@"NSApplicationBundleIdentifier"];
	
	if ([bundleId isEqual:@"com.apple.iTunes"]) {
		//[updateTimer invalidate];
		//[[NSApplication sharedApplication] terminate:self];
	}
}

- (void)updateTimerFired:(NSTimer *)timer {
	ETTrack *curTrack = [eyeTunes currentTrack];
	if(!curTrack)
		return;
	
	if ([trkName isEqual:[curTrack name]])
		return;
	
	self.trkName = [curTrack name];
	self.artName = [curTrack artist];
	self.albName = [curTrack album];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:AUTO_FETCH_CURRENT])
		[self fetchForCurrentTrack:self];
}

- (IBAction)fetchForSelectedTracks:(id)sender {
	if (!artName || !albName)
		return;
	
	for (ETTrack *track in [eyeTunes selectedTracks]) {
		TrackDesc *desc = [[TrackDesc alloc] initWithTrack:track];
		
		[coverFetcher addTrackDesc:desc];
		NSLog(@"Added: %@ - %@", [desc.track album], [desc.track name]);
		
		[desc release];
	}
}

- (IBAction)fetchForCurrentAlbum:(id)sender {
	if (!artName || !albName)
		return;
	
	NSString *searchStr = [[NSString alloc] initWithFormat:@"%@ %@", artName, albName];
	NSArray *albumTracks = [eyeTunes search:[eyeTunes libraryPlaylist] forString:searchStr inField:kETSearchAttributeAll];
	
	for (ETTrack *track in albumTracks) {
		if (![artName isEqualToString:[track artist]])
			continue;
		if (![albName isEqualToString:[track album]])
			continue;
		
		TrackDesc *desc = [[TrackDesc alloc] initWithTrack:track];
		[coverFetcher addTrackDesc:desc];
		NSLog(@"Added: %@ - %@", [desc.track album], [desc.track name]);
		[desc release];
	}
	
	[searchStr release];
}

- (IBAction)fetchForCurrentTrack:(id)sender {
	if (!artName || !albName)
		return;
	
	TrackDesc *desc = [[TrackDesc alloc] initWithTrack:[eyeTunes currentTrack]];
	[coverFetcher addTrackDesc:desc];
	NSLog(@"Added: %@ - %@", [desc.track album], [desc.track name]);
	[desc release];
}

@end
