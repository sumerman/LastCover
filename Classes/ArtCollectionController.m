//
//  ArtCollectionController.m
//  LastCover
//
//  Created by Valery Meleshkin on 14/11/13.
//
//

#import "ArtCollectionController.h"

@implementation ArtCollectionController

@synthesize noArtToggle;

- (NSArray *)arrangeObjects:(NSArray *)objects {
    if (noArtToggle) {
        [noArtToggle setTarget:self];
        [noArtToggle setAction:@selector(scheduleObjectsRearrange:)];
    }
    if (noArtToggle == nil || noArtToggle.state == NSOffState) {
        return [super arrangeObjects:objects];
    }
    
    return [super arrangeObjects:[objects filteredArrayUsingPredicate:
                                  [NSPredicate predicateWithFormat:@"hadArtwork = NO"]]];
}

- (IBAction)scheduleObjectsRearrange:(id)sender {
    [self rearrangeObjects];
}

@end
