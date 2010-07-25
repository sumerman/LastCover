//
//  LastCoverAppDelegate.h
//  LastCover
//
//  Created by Meleshkin Valeryi on 08.07.10.
//  Copyright 2010 Terem-media. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <EyeTunes/EyeTunes.h>

#import "CoverSaver.h"
#import "CoverFetcher.h"

@interface LastCoverAppDelegate : NSObject {
    NSWindow *window;
	
	NSStatusItem *sbarItem;
	NSMenu *sbarMenu;
	NSMenuItem *sbarShowConflicts;
	
	NSImage *sbarIcon;
	NSImage *sbarIconAlert;
	
	NSString *artName;
	NSString *albName;
	NSString *trkName;
	
	NSTimer *updateTimer;
	
	EyeTunes *eyeTunes;
	
	CoverSaver *coverSaver;
	CoverFetcher *coverFetcher;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenu *sbarMenu;
@property (assign) IBOutlet NSMenuItem *sbarShowConflicts;

@property (retain) NSImage *sbarIcon;
@property (retain) NSImage *sbarIconAlert;

@property (copy) NSString *artName;
@property (copy) NSString *albName;
@property (copy) NSString *trkName;


- (IBAction)fetchForCurrentAlbum:(id)sender;
- (IBAction)fetchForCurrentTrack:(id)sender;
- (IBAction)fetchForSelectedTracks:(id)sender;

- (IBAction)showCoverWindow:(id)sender;
- (void)applicationClosed:(NSNotification *)notif;

- (void)updateTimerFired:(NSTimer *)timer;


@end
