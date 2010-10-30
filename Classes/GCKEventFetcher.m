//
//  GCKEventFetcher.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKEventFetcher.h"
#import "GCKEventStore.h"
#import "GCKEvent.h"
#import "GCKAlarm.h"
#import "GCKParticipant.h"
#import "GCKRecurrenceRule.h"
#import "GCKRecurrenceEnd.h"
#import "GCKRecurrenceDayOfWeek.h"
#import "GCKOriginalEvent.h"
#import "GCKCalendar.h"
#import "GCKSync.h"
#import "GCKDateRange.h"
#import "RecurrenceRFC2445.h"
#import "NSDate+Additions.h"

static NSString * const kGoogleCalendarServiceIdentifier = @"http://www.google.com/calendar";

@implementation GCKEventFetcher

+ (GCKEventFetcher *)eventFetcherWithCalendar:(GCKCalendar *)cal 
                                         sync:(GCKSync *)s {
    GCKEventFetcher *fetcher = [[[GCKEventFetcher alloc] init] autorelease];
    fetcher.calendar = cal;
    fetcher.sync = s;
    return fetcher;
}

- (void)dealloc {
    LOG_CURRENT_METHOD;
    self.calendar = nil;
    self.sync = nil;
    [super dealloc];
}

- (void)fetchEventsForDateRange:(GCKDateRange *)dateRange {
    [self retain];
    
    NSURL *feedURL = calendar.feedURL;
    LOG(@"%@", feedURL);
    if (feedURL) {
        NSTimeZone *timeZone = calendar.timeZone;
        if (!timeZone) {
            timeZone = [[NSCalendar currentCalendar] timeZone];
        }
        
		GDataQueryCalendar *query = [GDataQueryCalendar calendarQueryWithFeedURL:feedURL];
        [query setCurrentTimeZoneName:[timeZone name]];
        [query setIsAscendingOrder:YES];
        
        NSDate *lastSyncedDate = calendar.lastSyncedDate;
        if (lastSyncedDate != nil) {
            [query setUpdatedMinDateTime:[GDataDateTime dateTimeWithDate:lastSyncedDate timeZone:timeZone]];
        }
        
        NSDate *startDate = dateRange.startDate;
        if (startDate) {
            [query setMinimumStartTime:[GDataDateTime dateTimeWithDate:startDate timeZone:timeZone]];
        }
        
        NSDate *endDate = dateRange.endDate;
        if (endDate) {
            [query setMaximumStartTime:[GDataDateTime dateTimeWithDate:endDate timeZone:timeZone]];
        }
        
		[[sync calendarService] fetchFeedWithQuery:query
                                          delegate:self
                                 didFinishSelector:@selector(calendarEventsTicket:finishedWithFeed:error:)];
	} else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kCalendarSyncFailedNotification object:sync];
        [self autorelease];
    }
}

- (void)calendarEventsTicket:(GDataServiceTicket *)ticket
            finishedWithFeed:(GDataFeedCalendarEvent *)feed
                       error:(NSError *)error {
    LOG_CURRENT_METHOD;
	if (error == nil) {
        GCKEventStore *eventStore = [GCKEventStore defaultEventStore];
        
        NSArray *entries = [feed entries];
        for (GDataEntryCalendarEvent *entry in entries) {
            NSString *identifier = [entry identifier];
            NSString *iCalUID = [entry iCalUID];
            
            NSString *eventStatus = [[entry eventStatus] stringValue];
            BOOL isCancelled = [eventStatus isEqualToString:kGDataEventStatusCanceled];
            
            NSString *title = [[entry title] stringValue];
            
            GDataWhere *where = [[entry locations] lastObject];
            NSString *location = [where stringValue];
            
            NSString *content = [[entry content] stringValue];
            
            GDataOriginalEvent *originalEventEntry = [entry originalEvent];
            NSString *originalID = [originalEventEntry originalID];
            
            GCKEvent *event = [eventStore eventWithIdentifier:identifier];
            
            if (isCancelled) {
                if (event) {
                    NSDate *indexDate = event.indexDate;
                    GCKRecurrenceRule *rule = event.recurrenceRule;
                    
                    if (event.originalEvent) {
                        event.originalEvent.isCanceled = [NSNumber numberWithBool:YES];
                        LOG(@"[DELETED] %@", title);
                    } else {
                        [eventStore remove:event];
                        LOG(@"[DELETED] %@", title);
                    }
                    
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:indexDate, @"date", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kEventsUpdatedNotification object:sync userInfo:userInfo];
                    
                    if (rule) {
                        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:indexDate, @"date", rule, @"recurrenceRule", nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kEventsUpdatedNotification object:sync userInfo:userInfo];
                    }
                    
                    continue;
                } else {
                    if (!originalID) {
                        LOG(@"[DELETED] %@", title);
                        continue;
                    }
                }
            }
            
            NSDate *oldIndexDate = nil;
            GCKRecurrenceRule *oldRecurrenceRule = nil;
            
            if (!event) {
                event = [eventStore eventForUID:identifier];
            } else {
                oldIndexDate = event.indexDate;
            }
            
            event.iCalUID = iCalUID;
            
            event.calendar = calendar;
            event.calendarIdentifier = calendar.calendarIdentifier;
            event.serviceIdentifier = kGoogleCalendarServiceIdentifier;
            event.editLink = [[[entry editLink] URL] absoluteString];
            
            if ([title length] == 0) {
                title = NSLocalizedString(@"Untitled", nil);
            }
            event.title = title;
            
            event.location = location;
            event.notes = content;
            
            NSString *recurrence = [[entry recurrence] stringValue];
            if ([recurrence length] > 0) {
                NSDictionary *recurrenceDictionary = [[RecurrenceRFC2445 recurrence] recurrenceDictionaryFromString:recurrence];
                
                if (recurrenceDictionary) {
                    LOG(@"%@", recurrenceDictionary);
                    GDataDateTime *recurStartDateTime = [recurrenceDictionary objectForKey:kStartDateKey];
                    GDataDateTime *recurEndDateTime = [recurrenceDictionary objectForKey:kEndDateKey];
                    NSArray *bydaydays = [recurrenceDictionary objectForKey:kRecurrenceByDayDays];
                    NSArray *bydayfreqs = [recurrenceDictionary objectForKey:kRecurrenceByDayFreq];
                    NSArray *bymonth = [recurrenceDictionary objectForKey:kRecurrenceByMonth];
                    NSArray *bymonthday = [recurrenceDictionary objectForKey:kRecurrenceByMonthDay];
                    NSArray *bysetpos = [recurrenceDictionary objectForKey:kRecurrenceBySetPos];
                    NSArray *byweeknumber = [recurrenceDictionary objectForKey:kRecurrenceByWeekNumber];
                    NSArray *byyearday = [recurrenceDictionary objectForKey:kRecurrenceByYearDay];
                    NSString *frequency = [recurrenceDictionary objectForKey:kRecurrenceFrequencyKey];
                    NSNumber *interval = [recurrenceDictionary objectForKey:kRecurrenceIntervalKey];
                    GDataDateTime *until = [recurrenceDictionary objectForKey:kRecurrenceUntilKey];
                    
                    BOOL allDay = ![recurStartDateTime hasTime];
                    event.allDay = [NSNumber numberWithBool:allDay];
                    if (allDay) {
                        event.startDate = [recurStartDateTime date];
                        event.endDate = [[recurEndDateTime date] dateBySubtractingDays:1];
                    } else {
                        event.startDate = [recurStartDateTime date];
                        event.endDate = [recurEndDateTime date];
                    }
                    
                    event.indexDate = [event.startDate dateByTruncatingTimes];
                    
                    GCKRecurrenceFrequency freq = GCKRecurrenceFrequencyDaily;
                    if (frequency) {
                        if ([frequency isEqualToString:@"daily"]) {
                            freq = GCKRecurrenceFrequencyDaily;
                        } else if ([frequency isEqualToString:@"weekly"]) {
                            freq = GCKRecurrenceFrequencyWeekly;
                        } else if ([frequency isEqualToString:@"monthly"]) {
                            freq = GCKRecurrenceFrequencyMonthly;
                        } else if ([frequency isEqualToString:@"yearly"]) {
                            freq = GCKRecurrenceFrequencyYearly;
                        }
                    }
                    
                    NSInteger intvl = 0;
                    if (interval) {
                        intvl = [interval integerValue];
                    }
                    
                    NSMutableSet *daysOfTheWeek = [NSMutableSet setWithCapacity:[bydaydays count]];
                    for (int i = 0; i < [bydaydays count]; i++) {
                        NSInteger dow = GCKSunday;
                        NSString *bydayday = [bydaydays objectAtIndex:i];
                        if ([bydayday isEqualToString:@"sunday"]) {
                            dow = GCKSunday;
                        } else if ([bydayday isEqualToString:@"monday"]) {
                            dow = GCKMonday;
                        } else if ([bydayday isEqualToString:@"tuesday"]) {
                            dow = GCKTuesday;
                        } else if ([bydayday isEqualToString:@"wednesday"]) {
                            dow = GCKWednesday;
                        } else if ([bydayday isEqualToString:@"thursday"]) {
                            dow = GCKThursday;
                        } else if ([bydayday isEqualToString:@"friday"]) {
                            dow = GCKFriday;
                        } else if ([bydayday isEqualToString:@"saturday"]) {
                            dow = GCKSaturday;
                        }
                        NSNumber *bydayfreq = [bydayfreqs objectAtIndex:i];
                        [daysOfTheWeek addObject:[GCKRecurrenceDayOfWeek dayOfWeek:dow weekNumber:[bydayfreq integerValue]]];
                    }
                    
                    GCKRecurrenceEnd *recurrenceEnd = nil;
                    NSDate *untilDate = [[until date] dateByTruncatingTimes];
                    if (untilDate) {
                        recurrenceEnd = [GCKRecurrenceEnd recurrenceEndWithDate:untilDate];
                    }
                    
                    GCKRecurrenceRule *recurrenceRule = [GCKRecurrenceRule recurrenceWithFrequency:freq 
                                                                                        interval:intvl
                                                                                   daysOfTheWeek:daysOfTheWeek 
                                                                                  daysOfTheMonth:bymonthday 
                                                                                 monthsOfTheYear:bymonth 
                                                                                  weeksOfTheYear:byweeknumber 
                                                                                   daysOfTheYear:byyearday 
                                                                                    setPositions:bysetpos 
                                                                                             end:recurrenceEnd];
                    
                    if (event.recurrenceRule) {
                        oldRecurrenceRule = [[event.recurrenceRule retain] autorelease];
                    }
                    
                    event.recurrenceRule = recurrenceRule;
                }
            } else {
                NSArray *times = [entry times];
                GDataWhen *when = [times lastObject];
                
                GDataDateTime *startDateTime = [when startTime];
                GDataDateTime *endDateTime = [when endTime];
                
                BOOL allDay = ![startDateTime hasTime];
                event.allDay = [NSNumber numberWithBool:allDay];
                
                if (allDay) {
                    event.startDate = [startDateTime date];
                    event.endDate = [[endDateTime date] dateBySubtractingDays:1];
                } else {
                    event.startDate = [startDateTime date];
                    event.endDate = [endDateTime date];
                }
                
                event.indexDate = [event.startDate dateByTruncatingTimes];
            }
            
            if (originalID) {
                GDataWhen *originalWhen = [originalEventEntry originalStartTime];
                
                GDataDateTime *originalStartDateTime = [originalWhen startTime];
                GDataDateTime *originalEndDateTime = [originalWhen endTime];
                
                GCKOriginalEvent *originalEvent = [eventStore originalEventForUID:originalID startDate:[originalStartDateTime date] endDate:[originalEndDateTime date]];
                originalEvent.isCanceled = [NSNumber numberWithBool:isCancelled];
                
                event.originalEvent = originalEvent;
            }
            
            NSArray *reminders = [entry reminders];
            NSMutableSet *alarms = [NSMutableSet setWithCapacity:[reminders count]];
            for (GDataReminder *reminder in reminders) {
                GDataDateTime *absoluteTime = [reminder absoluteTime];
                NSDate *absoluteDate = [absoluteTime date];
                if (!absoluteDate) {
                    NSString *minites = [reminder minutes];
                    if (minites) {
                        absoluteDate = [NSDate dateWithMinutes:[minites integerValue] before:event.startDate];
                    }
                }
                
                GCKAlarm *alarm = [eventStore alarmForAbsoluteDate:absoluteDate];
                [alarms addObject:alarm];
            }
            
            NSArray *participants = [entry participants];
            NSMutableSet *attendees = [NSMutableSet setWithCapacity:[participants count]];
            for (GDataWho *who in participants) {
                NSString *name = [who stringValue];
                NSString *email = [who email];
                
                GCKParticipantType type = GCKParticipantTypeUnknown;
                
                NSString *attendeeType = [[who attendeeType] stringValue];
                GCKParticipantRole role = GCKParticipantRoleUnknown;
                if ([attendeeType isEqualToString:kGDataWhoAttendeeTypeRequired]) {
                    role = GCKParticipantRoleRequired;
                } else if ([attendeeType isEqualToString:kGDataWhoAttendeeTypeOptional]) {
                    role = GCKParticipantRoleOptional;
                }
                
                NSString *attendeeStatus = [[who attendeeStatus] stringValue];
                GCKParticipantStatus status = GCKParticipantStatusUnknown;
                if ([attendeeStatus isEqualToString:kGDataWhoAttendeeStatusInvited]) {
                    status = GCKParticipantStatusPending;
                } else if ([attendeeStatus isEqualToString:kGDataWhoAttendeeStatusAccepted]) {
                    status = GCKParticipantStatusAccepted;
                } else if ([attendeeStatus isEqualToString:kGDataWhoAttendeeStatusTentative]) {
                    status = GCKParticipantStatusTentative;
                } else if ([attendeeStatus isEqualToString:kGDataWhoAttendeeStatusDeclined]) {
                    status = GCKParticipantStatusDeclined;
                }
                
                GCKParticipant *participant = [eventStore participantForName:name];
                participant.email = email;
                participant.participantRole = [NSNumber numberWithInteger:role];
                participant.participantType = [NSNumber numberWithInteger:type];
                participant.participantStatus = [NSNumber numberWithInteger:status];
                
                [attendees addObject:participant];
            }
            
            if ([alarms count] > 0) {
                [event addAlarms:alarms];
            }
            
            if ([attendees count] > 0) {
                [event addAttendees:attendees];
            }
            
            if (oldIndexDate) {
                LOG(@"[UPDATED] %@ %@ %@ %@", title, event.startDate, event.endDate, [eventStatus stringByReplacingOccurrencesOfString:@"http://schemas.google.com/g/2005#event." withString:@""]);
                
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:oldIndexDate, @"date", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:kEventsUpdatedNotification object:sync userInfo:userInfo];
                
                if (oldRecurrenceRule) {
                    userInfo = [NSDictionary dictionaryWithObjectsAndKeys:oldIndexDate, @"date", oldRecurrenceRule, @"recurrenceRule", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kEventsUpdatedNotification object:sync userInfo:userInfo];
                }
                
                NSDate *indexDate = event.indexDate;
                NSArray *datesInRange = [GCKDateRange datesFromDate:indexDate toDate:event.endDate];
                for (NSDate *dateInRange in datesInRange) {
                    userInfo = [NSDictionary dictionaryWithObjectsAndKeys:dateInRange, @"date", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kEventsUpdatedNotification object:sync userInfo:userInfo];
                }
                
                if (event.recurrenceRule) {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:oldIndexDate, @"date", event.recurrenceRule, @"recurrenceRule", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kEventsUpdatedNotification object:sync userInfo:userInfo];
                }
            } else {
                LOG(@"[INSERTED] %@ %@ %@ %@", title, event.startDate, event.endDate, [eventStatus stringByReplacingOccurrencesOfString:@"http://schemas.google.com/g/2005#event." withString:@""]);
                
                NSDate *indexDate = event.indexDate;
                NSArray *datesInRange = [GCKDateRange datesFromDate:indexDate toDate:event.endDate];
                for (NSDate *dateInRange in datesInRange) {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:dateInRange, @"date", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kEventsUpdatedNotification object:sync userInfo:userInfo];
                }
                
                if (event.recurrenceRule) {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:indexDate, @"date", event.recurrenceRule, @"recurrenceRule", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kEventsUpdatedNotification object:sync userInfo:userInfo];
                }
            }
        }
        
        GDataLink *nextLink = [feed nextLink];
        if (nextLink) {
            NSError *error = nil;
            if ([eventStore save:&error]) {
            } else {
                LOG(@"%@", [error localizedDescription]);
            }
            
            LOG(@"Fetch Next Link: %@", nextLink);
            GDataServiceGoogleCalendar *service = [sync calendarService];
            [service fetchEntryWithURL:[nextLink URL] delegate:self didFinishSelector:@selector(calendarEventsTicket:finishedWithFeed:error:)];
            
            return;
        }
        
        NSError *error = nil;
        if ([eventStore save:&error]) {
            calendar.lastSyncedDate = [NSDate date];            
            [[NSNotificationCenter defaultCenter] postNotificationName:kCalendarSyncFinishedNotification object:sync userInfo:nil];
        } else {
            LOG(@"%@", [error localizedDescription]);
            [[NSNotificationCenter defaultCenter] postNotificationName:kCalendarSyncFailedNotification object:sync userInfo:nil];
        }
	} else {
        LOG(@"%@", [error localizedDescription]);
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  error, @"error",nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kCalendarSyncFailedNotification object:sync userInfo:userInfo];
    }
    
    [self autorelease];
}

@end
