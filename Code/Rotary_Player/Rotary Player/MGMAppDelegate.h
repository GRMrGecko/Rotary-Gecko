//
//  MGMAppDelegate.h
//  Rotary Player
//
//  Created by Mr. Gecko's Media (James Coleman) on 1/28/14.
//  No Copyright Claimed. Public Domain.
//

#import <Cocoa/Cocoa.h>

@class MGMSound;

@interface MGMAppDelegate : NSObject <NSApplicationDelegate> {
	IBOutlet NSWindow *window;
	IBOutlet NSTextField *statusField;
	IBOutlet NSTextField *lastInfoField;
	
	IBOutlet NSTextField *song1Field;
	IBOutlet NSTextField *song2Field;
	IBOutlet NSTextField *song3Field;
	IBOutlet NSTextField *song4Field;
	IBOutlet NSTextField *song5Field;
	IBOutlet NSTextField *song6Field;
	IBOutlet NSTextField *song7Field;
	IBOutlet NSTextField *song8Field;
	IBOutlet NSTextField *song9Field;
	
	MGMSound *songPlaying;
}
- (IBAction)connect:(id)sender;
- (IBAction)disconnect:(id)sender;

- (IBAction)chooseSong:(id)sender;
@end
