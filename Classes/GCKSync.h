//
//  GCKSync.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GData.h"

extern NSString * const kCalendarsUpdatedNotification;
extern NSString * const kCalendarsUpdateFailedNotification;
extern NSString * const kCalendarSyncFinishedNotification;
extern NSString * const kCalendarSyncFailedNotification;
extern NSString * const kEventsUpdatedNotification;

@class GCKCalendar, GCKDateRange;

@interface GCKSync : NSObject {
    NSString *username;
    NSString *password;
}

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

+ (GCKSync *)syncWithUsername:(NSString *)user password:(NSString *)pass;
- (GDataServiceGoogleCalendar *)calendarService;
- (id)initWithUsername:(NSString *)user password:(NSString *)pass;
- (void)fetchAllCalendars;
- (void)syncWithCalendar:(GCKCalendar *)calendar;
- (void)fetchEventsForDateRange:(GCKDateRange *)dateRange calendar:(GCKCalendar *)calendar;

@end
