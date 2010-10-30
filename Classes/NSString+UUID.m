//
//  NSString+UUID.m
//  GoogleCalendarKit
//
//  Created by KISHIKAWA Katsumi on 09/03/14.
//  Copyright 2009 KISHIKAWA Katsumi. All rights reserved.
//

#import "NSString+UUID.h"

@implementation NSString(UUID)

+ (NSString *)UUID {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return [(NSString *)uuidStr autorelease];
}

@end
