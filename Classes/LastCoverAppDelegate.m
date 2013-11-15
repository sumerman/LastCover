//
//  LastCoverAppDelegate.m
//  LastCover
//
//  Created by Meleshkin Valery on 08.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import "LastCoverAppDelegate.h"
#import "Album.h"

@implementation LastCoverAppDelegate

@synthesize window, albumsController, ready;

- (iTunesApplication *)itunes {
    return iTunesApp;
}

#pragma mark -
#pragma mark Application Lifecycle

- (void)awakeFromNib {
    _albums = [[NSMutableArray alloc] init];
    jobs = [[NSOperationQueue alloc] init];
    jobs.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	iTunesApp = [SBApplication applicationWithBundleIdentifier: @"com.apple.iTunes"];
    [self reload:self];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if (self.ready && [jobs operationCount] > 0) {
        return NSTerminateCancel;
    }
    return NSTerminateNow;
}

#pragma mark -
#pragma mark Events

- (IBAction)reload:(id)sender {
    if ([jobs operationCount] > 0) return;
    self.ready = NO;
    __block LastCoverAppDelegate *bSelf = self;
    [jobs waitUntilAllOperationsAreFinished];
    NSMutableArray *albumsA = [self mutableArrayValueForKey:@"albums"];
    [albumsA removeAllObjects];
    [jobs addOperationWithBlock:^{
        NSMutableDictionary *artists = [[NSMutableDictionary alloc] init];
        for (iTunesSource *src in [iTunesApp sources]) {
            if (src.kind != iTunesESrcLibrary) continue;
            for(iTunesLibraryPlaylist *pl in src.playlists) {
                if (pl.specialKind != iTunesESpKMusic) continue;
                for (iTunesTrack *t in pl.tracks) {
                    NSString *artist = t.artist;
                    if (t.albumArtist.length > 0)
                        artist = t.albumArtist;
                    NSMutableDictionary *albums = [artists objectForKey:[artist lowercaseString]];
                    if (!albums) {
                        albums = [[NSMutableDictionary alloc] init];
                        [artists setObject:albums forKey:[artist lowercaseString]];
                    }
                    Album *album = [albums objectForKey:[t.album lowercaseString]];
                    if (!album) {
                        album = [[Album alloc] init];
                        album.artist = artist;
                        album.name = t.album;
                        [albums setObject:album forKey:[t.album lowercaseString]];
                        
                        BOOL alreadyHasAw = t.artworks.count > 0;
                        iTunesArtwork *aw = t.artworks[0];
                        if (!alreadyHasAw) {
                            [album fetchCover:nil];
                        }
                        else {
                            album.artwork = [[NSImage alloc] initWithData:aw.rawData];
                        }
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [albumsA addObject:album];
                            album.hadArtwork = alreadyHasAw; // setting this prop here gives nice effect while scan in progress
                        }];
                    }
                    [album.tracks addObject:t];
                }
            }
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [albumsController rearrangeObjects];
            bSelf.ready = YES;
        }];

    }];
}

- (IBAction)saveAll:(id)sender {
    if (!self.ready) return;
    __block LastCoverAppDelegate *bSelf = self;
    [jobs addOperationWithBlock:^{
        [bSelf.albumsController.arrangedObjects
         enumerateObjectsUsingBlock:^(Album *obj, NSUInteger idx, BOOL *stop) {
            [obj saveCover];
        }];
    }];
}


@end
