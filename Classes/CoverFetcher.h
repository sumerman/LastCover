//
//  CoverFetcher.h
//  LastCover
//
//  Created by Meleshkin Valery on 23.07.10.
//  Copyright 2010 Meleshkin Valery. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^FetchFail) (NSArray *failedTracks);
void FetchBatch(NSArray *tracks, FetchFail onfail);
