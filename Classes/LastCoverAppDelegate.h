//
//  LastCoverAppDelegate.h
//  LastCover
//
//  Created by Meleshkin Valery on 08.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"

@interface LastCoverAppDelegate : NSObject {
	iTunesApplication *iTunesApp;
    NSOperationQueue *jobs;
}

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSArrayController *albumsController;
@property (strong) NSMutableArray *albums;
@property (assign) BOOL ready;

- (iTunesApplication *)itunes;
- (IBAction)reload:(id)sender;
- (IBAction)saveAll:(id)sender;

@end
