//
//  ArtCollectionController.h
//  LastCover
//
//  Created by Valery Meleshkin on 14/11/13.
//
//

#import <Cocoa/Cocoa.h>

@interface ArtCollectionController : NSArrayController

@property (weak) IBOutlet NSButton *noArtToggle;

- (IBAction)scheduleObjectsRearrange:(id)sender;

@end
