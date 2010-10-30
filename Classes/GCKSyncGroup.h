//
//  GCKSyncGroup.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCKSync.h"
#import "GCKCalendar.h"

extern NSString * const kSyncGroupStartedNotification;
extern NSString * const kSyncGroupFinishedNotification;

@class SPGoogleCalendarSync;

@interface GCKSyncGroup : NSObject {
    NSMutableArray *syncGroup;
    NSMutableArray *calendars;
}

+ (GCKSyncGroup *)syncGroup;
- (void)addSync:(GCKSync *)sync calendar:(GCKCalendar *)calendar;
- (void)start;

@end
