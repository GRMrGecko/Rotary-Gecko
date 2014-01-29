//
//  MGMSerial.m
//  Rotary Player
//
//  Created by Mr. Gecko's Media (James Coleman) on 1/28/14.
//  No Copyright Claimed. Public Domain.
//

#import "MGMSerial.h"
#import <IOKit/serial/IOSerialKeys.h>
#import <IOKit/serial/ioss.h>
#include <sys/ioctl.h>

NSString * const MGMSerialPortsFoundNotification = @"MGMSerialPortsFoundNotification";
NSString * const MGMSerialPortsRemovedNotification = @"MGMSerialPortsRemovedNotification";

int const MGMSerialPortMaxLine = 4096;

@interface MGMSerialPorts (MGMPrivate)
- (MGMSerialPort *)nextPort:(io_iterator_t)iterator;
@end

@interface MGMSerialPort (MGMPrivate)

@end


void MGMSerialPortFound(void *refcon, io_iterator_t iterator) {
	
}
void MGMSerialPortDidRemove(void *refcon, io_iterator_t iterator) {
	
}

static MGMSerialPorts *MGMSharedSerialPorts = nil;

@implementation MGMSerialPorts
+ (id)sharedSerialPorts {
	@synchronized(self) {
        if (MGMSharedSerialPorts==nil) {
			MGMSharedSerialPorts = [self new];
		}
    }
    return MGMSharedSerialPorts;
}
- (id)init {
	if ((self = [super init])) {
		serialPorts = [NSMutableArray new];
		
		CFMutableDictionaryRef servicesMatch = IOServiceMatching(kIOSerialBSDServiceValue);
		if (servicesMatch!=NULL) {
			CFDictionarySetValue(servicesMatch, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDAllTypes));
			CFMutableDictionaryRef servicesMatchRemoved = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, servicesMatch);
			
			notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
			runLoop = IONotificationPortGetRunLoopSource(notificationPort);
			CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoop, kCFRunLoopDefaultMode);
			
			
			io_iterator_t found;
			kern_return_t result = IOServiceAddMatchingNotification(notificationPort, kIOPublishNotification, servicesMatch, MGMSerialPortFound, self, &found);
			if (result!=kIOReturnSuccess)
				NSLog(@"Unable to register for serial add %d", result);
			MGMSerialPort *port;
			while ((port = [self nextPort:found])) {
				[serialPorts addObject:port];
			}
			IOObjectRelease(found);
			
			
			result = IOServiceAddMatchingNotification(notificationPort, kIOTerminatedNotification, servicesMatchRemoved, MGMSerialPortDidRemove, self, &found);
			if (result!=kIOReturnSuccess) {
				NSLog(@"Unable to register for serial remove %d", result);
			} else {
				MGMSerialPort *port;
				while ((port = [self nextPort:found])) {
					[serialPorts removeObject:port];
				}
				IOObjectRelease(found);
			}
		}
	}
	return self;
}
- (MGMSerialPort *)nextPort:(io_iterator_t)iterator {
	io_object_t serialPort = IOIteratorNext(iterator);
	if (serialPort != 0) {
		NSString *portName = [(NSString *)IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOTTYDeviceKey), kCFAllocatorDefault, 0) autorelease];
		NSString *portPath = [(NSString *)IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOCalloutDeviceKey), kCFAllocatorDefault, 0) autorelease];
		NSString *portType = [(NSString *)IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOSerialBSDTypeKey), kCFAllocatorDefault, 0) autorelease];
		IOObjectRelease(serialPort);
		if (portName!=nil && portPath!=nil) {
			MGMSerialPort *port = [self portForPath:portPath];
			if (port!=nil) {
				return port;
			}
			return [MGMSerialPort portWithPath:portPath name:portName type:portType speed:0 delegate:nil];
		}
	}
	return nil;
}

- (void)portsFound:(io_iterator_t)found {
	NSMutableArray *addedPorts = [NSMutableArray array];
	MGMSerialPort *port;
	while ((port = [self nextPort:found])) {
		[serialPorts addObject:port];
		[addedPorts addObject:port];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:MGMSerialPortsFoundNotification object:self userInfo:[NSDictionary dictionaryWithObject:addedPorts forKey:@"ports"]];
}

- (void)postsRemoved:(io_iterator_t)removed {
	NSMutableArray *removedPorts = [NSMutableArray array];
	MGMSerialPort *port;
	while ((port = [self nextPort:removed])) {
		[port close];
		[removedPorts addObject:port];
		[serialPorts removeObject:port];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:MGMSerialPortsRemovedNotification object:self userInfo:[NSDictionary dictionaryWithObject:removedPorts forKey:@"ports"]];
}

- (NSArray *)serialPorts {
	return serialPorts;
}
- (MGMSerialPort *)portForName:(NSString *)portName {
	for (int i=0; i<[serialPorts count]; i++) {
		if ([[(MGMSerialPort *)[serialPorts objectAtIndex:i] name] isEqualToString:portName])
			return [serialPorts objectAtIndex:i];
	}
	return nil;
}
- (MGMSerialPort *)portForPath:(NSString *)portPath {
	for (int i=0; i<[serialPorts count]; i++) {
		if ([[(MGMSerialPort *)[serialPorts objectAtIndex:i] path] isEqualToString:portPath])
			return [serialPorts objectAtIndex:i];
	}
	return nil;
}
- (NSArray *)portsOfType:(NSString *)portType {
	NSMutableArray *ports = [NSMutableArray array];
	for (int i=0; i<[serialPorts count]; i++) {
		if ([[(MGMSerialPort *)[serialPorts objectAtIndex:i] type] isEqualToString:portType])
			[ports addObject:[serialPorts objectAtIndex:i]];
	}
	return ports;
}
@end

@implementation MGMSerialPort
+ (id)portWithPath:(NSString *)thePath name:(NSString *)theName type:(NSString *)theType speed:(int)theSpeed delegate:(id)theDelegate {
	return [[[self alloc] initWithPath:thePath name:theName type:theType speed:theSpeed delegate:theDelegate] autorelease];
}
- (id)initWithPath:(NSString *)thePath name:(NSString *)theName type:(NSString *)theType speed:(int)theSpeed delegate:(id)theDelegate {
	if ((self = [super init])) {
		portPath = [thePath copy];
		portName = [theName copy];
		portType = [theType copy];
		portSpeed = theSpeed;
		
		fileDescriptor = -1;
		
		readLock = [NSLock new];
		closeLock = [NSLock new];
		
		delegate = [theDelegate retain];
		
		stopBackgroundRead = YES;
	}
	return self;
}

- (NSString *)description {
	return  [NSString stringWithFormat:@"<%@: %p %@ %@>", NSStringFromClass([self class]), self, portPath, portName];
}
- (NSString *)path {
	return portPath;
}
- (NSString *)name {
	return portName;
}
- (NSString *)type {
	return portType;
}

- (BOOL)isOpen {
	return (fileDescriptor>=0);
}
- (BOOL)open {
	if (fileDescriptor>=0)
		return YES;
	fileDescriptor = open([portPath fileSystemRepresentation], O_RDWR | O_NOCTTY | O_NONBLOCK);
	
	if (fileDescriptor<0) {
		fileDescriptor = -1;
		NSLog(@"Unable to open.");
		return NO;
	} else if (portSpeed!=0) {
		speed_t newSpeed = portSpeed;
		int errorCode = ioctl(fileDescriptor, IOSSIOSPEED, &newSpeed, 1);
		if (errorCode==-1) {
			if (fileDescriptor>=0)
				close(fileDescriptor);
			fileDescriptor = -1;
		}
	}
	return YES;
}
- (void)close {
	if (fileDescriptor>=0) {
		stopBackgroundRead = YES;
		[closeLock lock];
		
		close(fileDescriptor);
		fileDescriptor = -1;
		
		[closeLock unlock];
	}
}

- (long)speed {
	return portSpeed;
}
- (BOOL)setSpeed:(long)theSpeed {
	if (fileDescriptor >= 0) {
		speed_t newSpeed = theSpeed;
		int errorCode = ioctl(fileDescriptor, IOSSIOSPEED, &newSpeed, 1);
		if (errorCode == -1) {
			return NO;
		} else {
			portSpeed = theSpeed;
		}
	} else {
		portSpeed = theSpeed;
	}
	return YES;
}

- (id<MGMSerialPortDelegate>)delegate {
	return delegate;
}
- (void)setDelegate:(id)theDelegate {
	[delegate autorelease];
	delegate = [theDelegate retain];
}

- (BOOL)writeData:(NSData *)data {
	const char *dataBytes = (const char *)[data bytes];
	NSUInteger dataLenth = [data length];
	ssize_t bytesWritten = 0;
	if (dataBytes!=NULL && dataLenth>0) {
		bytesWritten = write(fileDescriptor, dataBytes, dataLenth);
		if ((NSUInteger)bytesWritten==dataLenth) {
			return YES;
		}
	}
	return NO;
}
- (BOOL)writeString:(NSString *)string usingEncoding:(NSStringEncoding)encoding {
	return [self writeData:[string dataUsingEncoding:encoding]];
}

- (NSData *)readData:(int)theByteCount {
	[readLock lock];
	[closeLock lock];
	
	NSData *data = nil;
	void *buffer = malloc(theByteCount);
	ssize_t bytesRead = 0;
	fd_set *readFDs = NULL;
	
	if (fileDescriptor>=0) {
		readFDs = (fd_set *)malloc(sizeof(fd_set));
		FD_ZERO(readFDs);
		FD_SET(fileDescriptor, readFDs);
		int result = select(fileDescriptor+1, readFDs, nil, nil, nil);
		if (result>=1 && fileDescriptor>=0)
			bytesRead = read(fileDescriptor, buffer, theByteCount);
		free(readFDs);
		readFDs = NULL;
		if (bytesRead==0) {
			[closeLock unlock];
			[readLock unlock];
			free(buffer);
			return nil;
		}
		data = [NSData dataWithBytes:buffer length:bytesRead];
	}
	
	free(buffer);
	
	[closeLock unlock];
	[readLock unlock];
	return data;
}
- (BOOL)readDataInBackgroundNewLine {
	if ([delegate respondsToSelector:@selector(serial:read:)] && stopBackgroundRead && fileDescriptor>=0) {
		stopBackgroundRead = NO;
		[NSThread detachNewThreadSelector:@selector(readDataBackgroundThread) toTarget:self withObject:nil];
		return YES;
	}
	return NO;
}
- (void)stopBackgroundRead {
	stopBackgroundRead = YES;
}
- (void)readDataBackgroundThread {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	while (!stopBackgroundRead) {
		NSMutableData *data = [NSMutableData new];
		
		while (!stopBackgroundRead) {
			NSData *readData = [self readData:1];
			if (readData!=nil) {
				if (strcmp([readData bytes], "\n")==0 || strcmp([readData bytes], "\r")==0) {
					if ([data length]<=0)
						continue;
					break;
				} else {
					if ([data length]>=MGMSerialPortMaxLine)
						break;
					[data appendData:readData];
				}
			}
			[pool drain];
			pool = [NSAutoreleasePool new];
		}
		
		if ([data length]>0 && !stopBackgroundRead) {
			SEL readSelector = @selector(serial:read:);
			NSMethodSignature *signature = [(NSObject *)delegate methodSignatureForSelector:readSelector];
			if (signature!=nil) {
				NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
				[invocation setSelector:readSelector];
				[invocation setArgument:&self atIndex:2];
				[invocation setArgument:&data atIndex:3];
				[invocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:delegate waitUntilDone:YES];
			}
		}
		
		[data release];
	}
	
	[pool drain];
}
@end
