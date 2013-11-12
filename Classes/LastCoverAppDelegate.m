//
//  LastCoverAppDelegate.m
//  LastCover
//
//  Created by Meleshkin Valery on 08.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import "LastCoverAppDelegate.h"
#import "DefaultsDefines.h"

@implementation LastCoverAppDelegate

@synthesize window, artName, albName, trkName, sbarMenu, sbarShowConflicts, sbarIcon, sbarIconAlert;

+ (void)initialize {
	NSDictionary *appDefaults = @{AUTO_FETCH_CURRENT: @YES};
	[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
}


- (iTunesApplication *)itunes {
    return iTunesApp;
}

#pragma mark -
#pragma mark Application Lifecycle


#define LOAD_ICON(name) {\
	NSString *sbarImgPath = [[NSBundle mainBundle] pathForResource:@#name ofType:@"png"]; \
	NSImage *sbarImg = [[NSImage alloc] initWithContentsOfFile:sbarImgPath]; \
	[sbarImg setSize:NSMakeSize(20.0, 20.0)]; \
	self.name = sbarImg; \
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
	iTunesApp = [SBApplication applicationWithBundleIdentifier: @"com.apple.iTunes"];
	
	LOAD_ICON(sbarIcon);
	LOAD_ICON(sbarIconAlert);
	
	// status bar menu building 
	sbarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
	[sbarItem setMenu:sbarMenu];
	[sbarItem setImage:self.sbarIcon];
	[sbarItem setHighlightMode:YES];
	
	// subscribe to application-terminated notifications
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self 
														   selector:@selector(applicationClosed:)
															   name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	
	// schedule timer for periodically updates
	updateTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
												   target:self 
												 selector:@selector(updateTimerFired:) 
												 userInfo:nil 
												  repeats:YES];
}

#undef LOAD_ICON

- (void) dealloc
{
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	
	[updateTimer invalidate];
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

- (void) fetchTracksBatch:(NSArray *)b {
    FetchBatch(b, ^(NSArray *fails) {
        iTunesTrack *track = [fails lastObject];
        NSUserNotification *notif = [[NSUserNotification alloc] init];
        notif.title = @"Cover fetch failed";
        notif.informativeText = [[NSString alloc] initWithFormat:@"%@ — %@", track.artist, track.album];
        notif.hasActionButton = true;
        notif.actionButtonTitle = @"Retry";
        notif.userInfo = @{@"artist": track.artist,
                           @"album": track.album};
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notif];
    });
}

#pragma mark -
#pragma mark Events

- (IBAction)showCoverWindow:(id)sender {
	NSLog(@"show!");
	[window makeKeyAndOrderFront:self];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)applicationClosed:(NSNotification *)notif {
	NSString *bundleId = [notif userInfo][@"NSApplicationBundleIdentifier"];
	
	if ([bundleId isEqual:@"com.apple.iTunes"]) {
		//[updateTimer invalidate];
		//[[NSApplication sharedApplication] terminate:self];
	}
}

- (void)updateTimerFired:(NSTimer *)timer {
	iTunesTrack *curTrack = iTunesApp.currentTrack;
	if(!curTrack)
		return;
	
	if ([trkName isEqual:curTrack.name])
		return;
	
	self.trkName = curTrack.name;
	self.artName = curTrack.artist;
	self.albName = curTrack.album;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:AUTO_FETCH_CURRENT])
		[self fetchForCurrentTrack:self];
}

- (IBAction)fetchForSelectedTracks:(id)sender {
    NSMutableArray *batch = iTunesApp.selection.get;
    [self fetchTracksBatch:batch];
}

- (IBAction)fetchForCurrentAlbum:(id)sender {
	if (!artName || !albName)
		return;
    [self fetchForCurrentArtist:artName album:albName];
}

- (void)fetchForCurrentArtist:(NSString*)artist album:(NSString*)album {
    NSString *searchStr = [[NSString alloc] initWithFormat:@"%@ %@", artist, album];
    NSMutableArray *batch = [[NSMutableArray alloc] init];
	for (iTunesSource *src in [iTunesApp sources]) {
        if (src.kind != iTunesESrcLibrary) continue;
        for(iTunesLibraryPlaylist *pl in src.libraryPlaylists) {
            NSArray *albumTracks = [pl searchFor:searchStr only:iTunesESrAAll];
            for (iTunesTrack *track in albumTracks) {
                if (![artist isEqualToString:track.artist])
                    continue;
                if (![album isEqualToString:track.album])
                    continue;
                
                [batch addObject:track];
            }
        }
    }
    [self fetchTracksBatch:batch];
}

- (IBAction)fetchForCurrentTrack:(id)sender {
	if (!artName || !albName)
		return;
    
    [self fetchTracksBatch:@[iTunesApp.currentTrack]];
}

#pragma mark -
#pragma mark User Notification Center Delegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    NSString *art = notification.userInfo[@"artist"];
    NSString *alb = notification.userInfo[@"album"];
    [self fetchForCurrentArtist:art album:alb];
}


@end
