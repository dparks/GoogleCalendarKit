//
//  GCKEventStore.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKEventStore.h"
#import "GCKCalendar.h"
#import "GCKEvent.h"
#import "GCKAlarm.h"
#import "GCKParticipant.h"
#import "GCKOriginalEvent.h"
#import "GCKDateRange.h"
#import "GoogleCalendarKitAppDelegate.h"
#import "NSString+UUID.h"

@implementation GCKEventStore

+ (GCKEventStore *)defaultEventStore {
    static GCKEventStore *eventStore;
    if (!eventStore) {
        eventStore = [[GCKEventStore alloc] init];
    }
    return eventStore;
}

- (id)init {
    if (self = [super init]) {
        eventStoreIdentifier = [[NSString UUID] retain];
    }
    return self;
}

- (void)dealloc {
    [eventStoreIdentifier release];
    [calendars release];
    [defaultCalendarForNewEvents release];
    
    [super dealloc];
}

#pragma mark -

- (NSManagedObjectContext *)managedObjectContext {
    GoogleCalendarKitAppDelegate *app = (GoogleCalendarKitAppDelegate *)[[UIApplication sharedApplication] delegate];
    return [app managedObjectContext];
}

#pragma mark -

- (NSManagedObject *)objectWithID:(NSManagedObjectID *)objectID {
    NSManagedObjectContext *context = [self managedObjectContext];
    return [context objectWithID:objectID];
}

#pragma mark -

- (GCKCalendar *)calendarForIdentifier:(NSString *)identifier title:(NSString *)title color:(UIColor *)color {
    NSManagedObjectContext *context = [self managedObjectContext];
    
    GCKCalendar *calendar = [NSEntityDescription insertNewObjectForEntityForName:@"Calendar" inManagedObjectContext:context];
    calendar.calendarIdentifier = identifier;
    calendar.title = title;
    calendar.color = color;
    calendar.type = [NSNumber numberWithInteger:GCKCalendarTypeCalDAV];
    
    return calendar;
}

- (NSArray *)allCalendars {
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Calendar" inManagedObjectContext:context];
    
    request.entity = entity;
    
    NSArray *events = [context executeFetchRequest:request error:nil];
    
    [request release];
    
    return events;
}

#pragma mark -

- (GCKEvent *)eventForUID:(NSString *)UID {
    NSManagedObjectContext *context = [self managedObjectContext];
    
    GCKEvent *event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:context];
    
    event.eventIdentifier = UID;
    event.iCalUID = UID;
    event.calendar = defaultCalendarForNewEvents;
    event.calendarIdentifier = defaultCalendarForNewEvents.calendarIdentifier;
    
    return event;
}

- (GCKEvent *)eventForUID:(NSString *)UID occurrenceDate:(NSDate *)occurrenceDate {
    NSManagedObjectContext *context = [self managedObjectContext];
    
    GCKEvent *event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:context];
    
    event.eventIdentifier = UID;
    event.iCalUID = UID;
    event.calendar = defaultCalendarForNewEvents;
    event.calendarIdentifier = defaultCalendarForNewEvents.calendarIdentifier;
    
    GCKDateRange *dateRange = [GCKDateRange dateRangeWithDateToAfterAnHour:occurrenceDate];
    event.startDate = dateRange.startDate;
    event.endDate = dateRange.endDate;
    
    return event;
}

- (GCKOriginalEvent *)originalEventForUID:(NSString *)UID startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    NSManagedObjectContext *context = [self managedObjectContext];
    
    GCKOriginalEvent *originalEvent = [NSEntityDescription insertNewObjectForEntityForName:@"OriginalEvent" inManagedObjectContext:context];
    originalEvent.eventIdentifier = UID;
    originalEvent.startDate = startDate;
    originalEvent.endDate = endDate;
    return originalEvent;
}

- (NSPredicate *)predicateTemplateForMatchingIdentifier {
    static NSPredicate *predicateTemplateForMatchingIdentifier;
    if (!predicateTemplateForMatchingIdentifier) {
        predicateTemplateForMatchingIdentifier = [[NSPredicate predicateWithFormat:
                                                   @"eventIdentifier == $eventIdentifier"] retain];
    }
    return predicateTemplateForMatchingIdentifier;
}

- (NSPredicate *)predicateTemplateForMatchingICalUID {
    static NSPredicate *predicateTemplateForMatchingICalUID;
    if (!predicateTemplateForMatchingICalUID) {
        predicateTemplateForMatchingICalUID = [[NSPredicate predicateWithFormat:
                                                @"iCalUID == $iCalUID"] retain];
    }
    return predicateTemplateForMatchingICalUID;
}

- (GCKEvent *)eventWithIdentifier:(NSString *)identifier {
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:context];
    
    NSDictionary *variables = [[NSDictionary alloc] initWithObjectsAndKeys:
                               identifier, @"eventIdentifier", nil];
    NSPredicate *predicate = [[self predicateTemplateForMatchingIdentifier] predicateWithSubstitutionVariables:variables];
    [variables release];
    
    request.entity = entity;
    request.predicate = predicate;
    
    NSArray *events = [context executeFetchRequest:request error:nil];
    
    [request release];
    return [events lastObject];
}

- (GCKEvent *)eventWithICalUID:(NSString *)iCalUID {
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:context];
    
    NSDictionary *variables = [[NSDictionary alloc] initWithObjectsAndKeys:
                               iCalUID, @"iCalUID", nil];
    NSPredicate *predicate = [[self predicateTemplateForMatchingICalUID] predicateWithSubstitutionVariables:variables];
    [variables release];
    
    request.entity = entity;
    request.predicate = predicate;
    
    NSArray *events = [context executeFetchRequest:request error:nil];
    
    [request release];
    return [events lastObject];
}

- (NSPredicate *)predicateTemplateForMatchingDateRange {
    static NSPredicate *predicateTemplateForMatchingDateRange;
    if (!predicateTemplateForMatchingDateRange) {
        predicateTemplateForMatchingDateRange = [[NSPredicate predicateWithFormat:
                                                  @"startDate >= $minDate and startDate < $maxDate"] retain];
        
    }
    return predicateTemplateForMatchingDateRange;
}

- (NSArray *)eventsMatchingDateRange:(GCKDateRange *)dateRange {
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:context];
    
    NSDictionary *variables = [[NSDictionary alloc] initWithObjectsAndKeys:
                               dateRange.startDate, @"minDate", dateRange.endDate, @"maxDate", nil];
    NSPredicate *predicate = [[self predicateTemplateForMatchingDateRange] predicateWithSubstitutionVariables:variables];
    [variables release];
    
    request.entity = entity;
    request.predicate = predicate;
    
    NSSortDescriptor *allDaySortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"allDay" ascending:NO];
    NSSortDescriptor *startDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startDate" ascending:YES];
    NSSortDescriptor *calendarSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"calendar.title" ascending:YES];
    NSSortDescriptor *lastModifiedDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastModifiedDate" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:allDaySortDescriptor, startDateSortDescriptor, calendarSortDescriptor, lastModifiedDateSortDescriptor, nil];
    request.sortDescriptors = sortDescriptors;
    [allDaySortDescriptor release];
    [startDateSortDescriptor release];
    [calendarSortDescriptor release];
    [lastModifiedDateSortDescriptor release];
    [sortDescriptors release];
    
    NSArray *events = [context executeFetchRequest:request error:nil];
    
    [request release];
    
    return events;
}

#pragma mark -

- (GCKAlarm *)alarmForAbsoluteDate:(NSDate *)absoluteDate {
    NSManagedObjectContext *context = [self managedObjectContext];
    
    GCKAlarm *alarm = [NSEntityDescription insertNewObjectForEntityForName:@"Alarm" inManagedObjectContext:context];
    alarm.absoluteDate = absoluteDate;
    
    return alarm;
}

- (GCKParticipant *)participantForName:(NSString *)name {
    NSManagedObjectContext *context = [self managedObjectContext];
    
    GCKParticipant *participant = [NSEntityDescription insertNewObjectForEntityForName:@"Attendee" inManagedObjectContext:context];
    participant.name = name;
    
    return participant;
}

#pragma mark -

- (BOOL)save:(NSError **)error {
    LOG_CURRENT_METHOD;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *e = nil;
    if (![context save:&e]) {
        NSLog(@"Failed to save to data store: %@", [e localizedDescription]);
        NSArray *detailedErrors = [[e userInfo] objectForKey:NSDetailedErrorsKey];
        if (detailedErrors != nil && [detailedErrors count] > 0) {
            for (NSError *detailedError in detailedErrors) {
                NSLog(@"Detailed Error: %@", [detailedError userInfo]);
            }
        } else {
            NSLog(@"%@", [e userInfo]);
        }
        *error = e;
        return NO;
    }
    return YES;
}

- (void)rollback {
    NSManagedObjectContext *context = [self managedObjectContext];
    if ([context hasChanges]) {
        [context rollback];
    }
}

- (void)reset {
    NSManagedObjectContext *context = [self managedObjectContext];
    [context reset];
}

- (void)remove:(NSManagedObject *)obj {
    NSManagedObjectContext *context = [self managedObjectContext];
    [context deleteObject:obj];
}

- (NSPredicate *)predicateTemplateForCalendar {
    static NSPredicate *predicateTemplateForCalendar;
    if (!predicateTemplateForCalendar) {
        predicateTemplateForCalendar = [[NSPredicate predicateWithFormat:
                                         @"calendarIdentifier == $calendarIdentifier"] retain];
    }
    return predicateTemplateForCalendar;
}

- (void)removeCalendar:(GCKCalendar *)calendar {
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:context];
    
    NSLog(@"%@", calendar.calendarIdentifier);
    
    NSDictionary *variables = [[NSDictionary alloc] initWithObjectsAndKeys:
                               calendar.calendarIdentifier, @"calendarIdentifier", nil];
    NSPredicate *predicate = [[self predicateTemplateForCalendar] predicateWithSubstitutionVariables:variables];
    [variables release];
    
    request.entity = entity;
    request.predicate = predicate;
    
    NSArray *events = [context executeFetchRequest:request error:nil];
    LOG(@"[DELETE] %@", events);
    for (GCKEvent *event in events) {
        [context deleteObject:event];
    }
    NSError *error = nil;
    [self save:&error];
    
    [request release];
}

@end
