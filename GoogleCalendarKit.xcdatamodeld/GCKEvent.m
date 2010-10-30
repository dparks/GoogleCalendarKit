// 
//  GCKEvent.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKEvent.h"

#import "GCKAlarm.h"
#import "GCKCalendar.h"
#import "GCKOriginalEvent.h"
#import "GCKParticipant.h"
#import "GCKRecurrenceRule.h"

@implementation GCKEvent 

@dynamic eventIdentifier;
@dynamic location;
@dynamic allDay;
@dynamic title;
@dynamic availability;
@dynamic status;
@dynamic serviceIdentifier;
@dynamic organizer;
@dynamic indexDate;
@dynamic endDate;
@dynamic editLink;
@dynamic lastModifiedDate;
@dynamic geoLocation;
@dynamic imagePath;
@dynamic isDettached;
@dynamic startDate;
@dynamic notes;
@dynamic iCalUID;
@dynamic calendarIdentifier;
@dynamic calendar;
@dynamic attendees;
@dynamic originalEvent;
@dynamic recurrenceRule;
@dynamic alarms;

@end
