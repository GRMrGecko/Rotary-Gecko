//
//  MGMAppDelegate.m
//  Rotary Player
//
//  Created by Mr. Gecko's Media (James Coleman) on 1/28/14.
//  No Copyright Claimed. Public Domain.
//

#import "MGMAppDelegate.h"

#import "MGMSerial.h"
#import "MGMSound.h"

NSString * const serialPort = @"/dev/cu.RotaryGecko-SPPDev";
NSString * const MGMSong1 = @"song1";
NSString * const MGMSong2 = @"song2";
NSString * const MGMSong3 = @"song3";
NSString * const MGMSong4 = @"song4";
NSString * const MGMSong5 = @"song5";
NSString * const MGMSong6 = @"song6";
NSString * const MGMSong7 = @"song7";
NSString * const MGMSong8 = @"song8";
NSString * const MGMSong9 = @"song9";

@implementation MGMAppDelegate
- (void)awakeFromNib {
	MGMSerialPorts *ports = [MGMSerialPorts sharedSerialPorts];
	NSLog(@"%@", [ports serialPorts]);
	
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	if ([settings objectForKey:MGMSong1]!=nil)
		[song1Field setStringValue:[[[settings objectForKey:MGMSong1] lastPathComponent] stringByDeletingPathExtension]];
	if ([settings objectForKey:MGMSong2]!=nil)
		[song2Field setStringValue:[[[settings objectForKey:MGMSong2] lastPathComponent] stringByDeletingPathExtension]];
	if ([settings objectForKey:MGMSong3]!=nil)
		[song3Field setStringValue:[[[settings objectForKey:MGMSong3] lastPathComponent] stringByDeletingPathExtension]];
	if ([settings objectForKey:MGMSong4]!=nil)
		[song4Field setStringValue:[[[settings objectForKey:MGMSong4] lastPathComponent] stringByDeletingPathExtension]];
	if ([settings objectForKey:MGMSong5]!=nil)
		[song5Field setStringValue:[[[settings objectForKey:MGMSong5] lastPathComponent] stringByDeletingPathExtension]];
	if ([settings objectForKey:MGMSong6]!=nil)
		[song6Field setStringValue:[[[settings objectForKey:MGMSong6] lastPathComponent] stringByDeletingPathExtension]];
	if ([settings objectForKey:MGMSong7]!=nil)
		[song7Field setStringValue:[[[settings objectForKey:MGMSong7] lastPathComponent] stringByDeletingPathExtension]];
	if ([settings objectForKey:MGMSong8]!=nil)
		[song8Field setStringValue:[[[settings objectForKey:MGMSong8] lastPathComponent] stringByDeletingPathExtension]];
	if ([settings objectForKey:MGMSong9]!=nil)
		[song9Field setStringValue:[[[settings objectForKey:MGMSong9] lastPathComponent] stringByDeletingPathExtension]];
}
- (void)dealloc {
	[super dealloc];
}

- (IBAction)connect:(id)sender {
	MGMSerialPort *port = [[MGMSerialPorts sharedSerialPorts] portForPath:serialPort];
	[port setSpeed:9600];
	if ([port open]) {
		[statusField setStringValue:@"Connected"];
	} else {
		[statusField setStringValue:@"Unable to Connect"];
	}
	[port setDelegate:self];
	NSLog(@"%@", port);
	
	[port readDataInBackgroundNewLine];
}
- (IBAction)disconnect:(id)sender {
	[[[MGMSerialPorts sharedSerialPorts] portForPath:serialPort] close];
	[statusField setStringValue:@"Disconnected"];
}


- (void)serial:(MGMSerialPort *)thePort read:(NSData *)theBytes; {
	NSString *info = [[[NSString alloc] initWithData:theBytes encoding:NSUTF8StringEncoding] autorelease];
	[lastInfoField setStringValue:info];
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	if ([info hasPrefix:@"Dialed: "]) {
		NSString *number = [info substringFromIndex:8];
		NSString *song = [NSString stringWithFormat:@"song%@", number];
		if ([settings objectForKey:song]!=nil) {
			if (songPlaying!=nil) {
				[songPlaying stop];
				[songPlaying release];
			}
			songPlaying = [[MGMSound alloc] initWithContentsOfFile:[settings objectForKey:song]];
			[songPlaying setDelegate:self];
			[songPlaying play];
		}
		NSLog(@"%@", info);
	} else if ([info hasPrefix:@"Hook: "]) {
		NSString *status = [info substringFromIndex:6];
		if ([status isEqual:@"0"] && songPlaying!=nil) {
			[songPlaying stop];
			[songPlaying release];
			songPlaying = nil;
		}
		NSLog(@"%@", info);
	}
}

- (void)soundDidFinishPlaying:(MGMSound *)theSound {
	[songPlaying release];
	songPlaying = nil;
}

- (IBAction)chooseSong:(id)sender {
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:NO];
	[panel setCanChooseFiles:YES];
	long returnCode = [panel runModal];
	if (returnCode==NSOKButton) {
		NSString *path = [[panel URL] path];
		if ([[sender identifier] isEqual:@"1"]) {
			[song1Field setStringValue:[[path lastPathComponent] stringByDeletingPathExtension]];
			[settings setObject:path forKey:MGMSong1];
		} else if ([[sender identifier] isEqual:@"2"]) {
			[song2Field setStringValue:[[path lastPathComponent] stringByDeletingPathExtension]];
			[settings setObject:path forKey:MGMSong2];
		} else if ([[sender identifier] isEqual:@"3"]) {
			[song3Field setStringValue:[[path lastPathComponent] stringByDeletingPathExtension]];
			[settings setObject:path forKey:MGMSong3];
		} else if ([[sender identifier] isEqual:@"4"]) {
			[song4Field setStringValue:[[path lastPathComponent] stringByDeletingPathExtension]];
			[settings setObject:path forKey:MGMSong4];
		} else if ([[sender identifier] isEqual:@"5"]) {
			[song5Field setStringValue:[[path lastPathComponent] stringByDeletingPathExtension]];
			[settings setObject:path forKey:MGMSong5];
		} else if ([[sender identifier] isEqual:@"6"]) {
			[song6Field setStringValue:[[path lastPathComponent] stringByDeletingPathExtension]];
			[settings setObject:path forKey:MGMSong6];
		} else if ([[sender identifier] isEqual:@"7"]) {
			[song7Field setStringValue:[[path lastPathComponent] stringByDeletingPathExtension]];
			[settings setObject:path forKey:MGMSong7];
		} else if ([[sender identifier] isEqual:@"8"]) {
			[song8Field setStringValue:[[path lastPathComponent] stringByDeletingPathExtension]];
			[settings setObject:path forKey:MGMSong8];
		} else if ([[sender identifier] isEqual:@"9"]) {
			[song9Field setStringValue:[[path lastPathComponent] stringByDeletingPathExtension]];
			[settings setObject:path forKey:MGMSong9];
		}
	}
}
@end
