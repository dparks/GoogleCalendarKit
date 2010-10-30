//
//  GCKEventStore.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    GCKGCKanThisEvent,
    GCKGCKanFutureEvents
} GCKGCKan;

@class GCKCalendar, GCKEvent, GCKAlarm, GCKParticipant, GCKOriginalEvent, GCKDateRange;

@interface GCKEventStore : NSObject {
    NSString *eventStoreIdentifier;
    NSArray *calendars;
    GCKCalendar *defaultCalendarForNewEvents;
}

- (NSManagedObject *)objectWithID:(NSManagedObjectID *)objectID;

+ (GCKEventStore *)defaultEventStore;
- (GCKCalendar *)calendarForIdentifier:(NSString *)identifier title:(NSString *)title color:(UIColor *)color;
- (NSArray *)allCalendars;

- (GCKEvent *)eventForUID:(NSString *)UID;
- (GCKEvent *)eventForUID:(NSString *)UID occurrenceDate:(NSDate *)occurrenceDate;
- (GCKEvent *)eventWithIdentifier:(NSString *)identifier;
- (NSArray *)eventsMatchingDateRange:(GCKDateRange *)dateRange;

- (GCKOriginalEvent *)originalEventForUID:(NSString *)UID startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

- (GCKAlarm *)alarmForAbsoluteDate:(NSDate *)absoluteDate;
- (GCKParticipant *)participantForName:(NSString *)name;

- (BOOL)save:(NSError **)error;
- (void)rollback;
- (void)reset;
- (void)remove:(NSManagedObject *)obj;
- (void)removeCalendar:(GCKCalendar *)calendar;

@end
