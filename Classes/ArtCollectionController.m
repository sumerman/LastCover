//
//  ArtCollectionController.m
//  LastCover
//
//  Created by Valery Meleshkin on 14/11/13.
//
//

#import "ArtCollectionController.h"

@implementation ArtCollectionController

@synthesize noArtToggle, searchField;

- (NSPredicate *)buildPredicate {
    @autoreleasepool {
        NSMutableArray *preds = [NSMutableArray array];
        if (noArtToggle != nil && noArtToggle.state == NSOnState) {
            [preds addObject:
             [NSPredicate predicateWithFormat:@"hadArtwork = NO"]];
        }
        if (searchField != nil &&
            ![searchField.stringValue isEqualToString:@""]) {
            [preds addObject:
             [NSPredicate predicateWithFormat:
              @"name contains[cd] %@ || artist contains[cd] %@",
              searchField.stringValue, searchField.stringValue]];
        }
        if ([preds count] > 0) {
            return [NSCompoundPredicate andPredicateWithSubpredicates:preds];
        }
        else {
            return nil;
        }
    }
}

- (void)awakeFromNib {
    [self updatePredicate:nil];
}

- (IBAction)updatePredicate:(id)sender {
    __block ArtCollectionController *bSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        bSelf.filterPredicate = [bSelf buildPredicate];
    }];
}

@end
