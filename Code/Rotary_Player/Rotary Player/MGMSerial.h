//
//  MGMSerial.h
//  Rotary Player
//
//  Created by Mr. Gecko's Media (James Coleman) on 1/28/14.
//  No Copyright Claimed. Public Domain.
//

#import <Cocoa/Cocoa.h>

extern NSString * const MGMSerialPortsFoundNotification;
extern NSString * const MGMSerialPortsRemovedNotification;

@class MGMSerialPort;

@interface MGMSerialPorts : NSObject {
	NSMutableArray *serialPorts;
	
	IONotificationPortRef notificationPort;
	CFRunLoopSourceRef runLoop;
}
+ (id)sharedSerialPorts;

- (NSArray *)serialPorts;
- (MGMSerialPort *)portForName:(NSString *)theName;
- (MGMSerialPort *)portForPath:(NSString *)thePath;
- (NSArray *)portsOfType:(NSString *)theType;
@end

@protocol MGMSerialPortDelegate <NSObject>
- (void)serial:(MGMSerialPort *)thePort read:(NSData *)theBytes;
@end

@interface MGMSerialPort : NSObject {
	NSString *portPath;
	NSString *portName;
	NSString *portType;
	long portSpeed;
	int fileDescriptor;
	
	id<MGMSerialPortDelegate> delegate;
	
	NSLock *readLock;
	BOOL stopBackgroundRead;
	NSLock *closeLock;
}
+ (id)portWithPath:(NSString *)thePath name:(NSString *)theName type:(NSString *)theType speed:(int)theSpeed delegate:(id)theDelegate;
- (id)initWithPath:(NSString *)thePath name:(NSString *)theName type:(NSString *)theType speed:(int)theSpeed delegate:(id)theDelegate;

- (NSString *)path;
- (NSString *)name;
- (NSString *)type;

- (BOOL)isOpen;
- (BOOL)open;
- (void)close;

- (long)speed;
- (BOOL)setSpeed:(long)theSpeed;

- (id<MGMSerialPortDelegate>)delegate;
- (void)setDelegate:(id)theDelegate;

- (BOOL)writeData:(NSData *)data;
- (BOOL)writeString:(NSString *)string usingEncoding:(NSStringEncoding)encoding;

- (NSData *)readData:(int)theByteCount;
- (BOOL)readDataInBackgroundNewLine;
- (void)stopBackgroundRead;
@end
