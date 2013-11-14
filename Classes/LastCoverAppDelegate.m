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
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	iTunesApp = [SBApplication applicationWithBundleIdentifier: @"com.apple.iTunes"];
    [self reload:self];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if ([jobs operationCount] > 0) {
        return NSTerminateCancel;
    }
    return NSTerminateNow;
}

#pragma mark -
#pragma mark Events

- (IBAction)reload:(id)sender {
    if ([jobs operationCount] > 0)
        return;
    self.ready = NO;
    [jobs addOperationWithBlock:^{
        NSMutableArray *albumsA = [self mutableArrayValueForKey:@"albums"];
        [albumsA removeAllObjects];
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
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [albumsA addObject:album];
                        }];
                        
                        iTunesArtwork *aw = t.artworks[0];
                        album.artwork = [[NSImage alloc] initWithData:aw.rawData];
                        album.hadArtwork = album.artwork != nil;
                        if (!album.hadArtwork) {
                            [album fetchCover:nil];
                        }
                    }
                    [album.tracks addObject:t];
                }
            }
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [albumsController rearrangeObjects];
            self.ready = YES;
        }];
    }];
}


@end
