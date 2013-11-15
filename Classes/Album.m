//
//  Album.m
//  LastCover
//
//  Created by Valery Meleshkin on 15/11/13.
//
//

#import "Album.h"
#import "iTunes.h"
#import "CoverFetcher.h"

@implementation Album

@synthesize name, artist, tracks, artwork, hadArtwork, jobsq;

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    self.name = @"";
    self.artist = @"";
    self.tracks = [NSMutableArray new];
    self.busy = NO;
    self.hadArtwork = NO;
    
    return self;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"%@ by %@", self.name, self.artist];
}

- (BOOL) isEqual:(id)object {
    if (![self isKindOfClass:[object class]]) return NO;
    if ([[object name] isEqualToString:self.name])
        if ([[object artist] isEqualToString:self.artist])
            return YES;
    return NO;
}

- (void)addOp:(void(^)())f {
    if (self.busy) return;
    
    if (!jobsq) {
        jobsq = [NSOperationQueue currentQueue];
    }
    __block Album *bSelf = self;
    [jobsq addOperationWithBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            bSelf.busy = YES;
        }];
        f();
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            bSelf.busy = NO;
        }];
        [[NSOperationQueue mainQueue] waitUntilAllOperationsAreFinished];
    }];
}

- (IBAction)fetchCover:(id)sender {
    __block Album *bSelf = self;
    [self addOp:^ {
        NSImage *art = FetchCoverForArtistAlbum(bSelf.artist, bSelf.name);
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            bSelf.artwork = art;
        }];
    }];
}

- (IBAction)saveCover {
    if (self.hadArtwork) return;
    if (!self.artwork) return;
    
    __block Album *bSelf = self;
    [self addOp:^ {
        for (iTunesTrack *track in bSelf.tracks) {
            iTunesArtwork *aw = (track.artworks)[0];
            aw.data = bSelf.artwork;
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            bSelf.hadArtwork = YES;
        }];
    }];
}

@end