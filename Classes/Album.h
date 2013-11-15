//
//  Album.h
//  LastCover
//
//  Created by Valery Meleshkin on 15/11/13.
//
//

#import <Foundation/Foundation.h>

@interface Album : NSObject

@property (copy)     NSString *name;
@property (copy)     NSString *artist;
@property (assign)   BOOL hadArtwork;
@property (assign)   BOOL busy;
@property (strong)   NSImage *artwork;
@property (strong)   NSMutableArray *tracks;
@property (strong)   NSOperationQueue *jobsq;

- (IBAction)saveCover;
- (IBAction)fetchCover:(id)sender;

@end

