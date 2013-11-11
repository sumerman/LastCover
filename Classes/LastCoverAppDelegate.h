//
//  LastCoverAppDelegate.h
//  LastCover
//
//  Created by Meleshkin Valery on 08.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "iTunes.h"
#import "CoverSaver.h"
#import "CoverFetcher.h"

@interface LastCoverAppDelegate : NSObject <NSUserNotificationCenterDelegate> {
    NSWindow *__weak window;
	
	NSStatusItem *sbarItem;
	NSMenu *__weak sbarMenu;
	NSMenuItem *__weak sbarShowConflicts;
	
	NSImage *sbarIcon;
	NSImage *sbarIconAlert;
	
	NSString *artName;
	NSString *albName;
	NSString *trkName;
	
	NSTimer *updateTimer;
	
	iTunesApplication *iTunesApp;
	
	CoverSaver *coverSaver;
	CoverFetcher *coverFetcher;
}

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *sbarMenu;
@property (weak) IBOutlet NSMenuItem *sbarShowConflicts;

@property (strong) NSImage *sbarIcon;
@property (strong) NSImage *sbarIconAlert;

@property (copy) NSString *artName;
@property (copy) NSString *albName;
@property (copy) NSString *trkName;


- (IBAction)fetchForCurrentAlbum:(id)sender;
- (IBAction)fetchForCurrentTrack:(id)sender;
- (IBAction)fetchForSelectedTracks:(id)sender;

- (IBAction)showCoverWindow:(id)sender;
- (void)applicationClosed:(NSNotification *)notif;

- (void)updateTimerFired:(NSTimer *)timer;

- (iTunesApplication *) itunes;


@end
