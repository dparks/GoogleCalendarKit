//
//  GCKEvent.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <CoreData/CoreData.h>

@class GCKAlarm;
@class GCKCalendar;
@class GCKOriginalEvent;
@class GCKParticipant;
@class GCKRecurrenceRule;

@interface GCKEvent :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * eventIdentifier;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSNumber * allDay;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * availability;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSString * serviceIdentifier;
@property (nonatomic, retain) id organizer;
@property (nonatomic, retain) NSDate * indexDate;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSString * editLink;
@property (nonatomic, retain) NSDate * lastModifiedDate;
@property (nonatomic, retain) id geoLocation;
@property (nonatomic, retain) NSString * imagePath;
@property (nonatomic, retain) NSNumber * isDettached;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSString * iCalUID;
@property (nonatomic, retain) NSString * calendarIdentifier;
@property (nonatomic, retain) GCKCalendar * calendar;
@property (nonatomic, retain) NSSet* attendees;
@property (nonatomic, retain) GCKOriginalEvent * originalEvent;
@property (nonatomic, retain) GCKRecurrenceRule * recurrenceRule;
@property (nonatomic, retain) NSSet* alarms;

@end


@interface GCKEvent (CoreDataGeneratedAccessors)
- (void)addAttendeesObject:(GCKParticipant *)value;
- (void)removeAttendeesObject:(GCKParticipant *)value;
- (void)addAttendees:(NSSet *)value;
- (void)removeAttendees:(NSSet *)value;

- (void)addAlarmsObject:(GCKAlarm *)value;
- (void)removeAlarmsObject:(GCKAlarm *)value;
- (void)addAlarms:(NSSet *)value;
- (void)removeAlarms:(NSSet *)value;

@end

