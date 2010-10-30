//
//  GCKSync.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKSync.h"
#import "GCKEventFetcher.h"
#import "GCKEventStore.h"
#import "GCKCalendar.h"
#import "GCKDateRange.h"
#import "GCKGregorian.h"
#import "UIColor+Additions.h"

NSString * const kCalendarsUpdatedNotification = @"kCalendarsUpdatedNotification";
NSString * const kCalendarsUpdateFailedNotification = @"kCalendarsUpdateFailedNotification";
NSString * const kCalendarSyncFinishedNotification = @"kCalendarSyncFinishedNotification";
NSString * const kCalendarSyncFailedNotification = @"kCalendarSyncFailedNotification";
NSString * const kEventsUpdatedNotification = @"kEventsUpdatedNotification";

@implementation GCKSync

+ (GCKSync *)syncWithUsername:(NSString *)user password:(NSString *)pass {
    return [[[GCKSync alloc] initWithUsername:user password:pass] autorelease];
}

- (id)initWithUsername:(NSString *)user password:(NSString *)pass {
    if (self = [super init]) {
        self.username = user;
        self.password = pass;
    }
    return self;
}

- (void)dealloc {
    LOG_CURRENT_METHOD;
    self.username = nil;
    self.password = nil;
    [super dealloc];
}

#pragma mark -

- (GDataServiceGoogleCalendar *)calendarService {
    static GDataServiceGoogleCalendar *service;
    
    if (!service) {
        service = [[GDataServiceGoogleCalendar alloc] init];
        
        [service setShouldCacheDatedData:YES];
        [service setServiceShouldFollowNextLinks:NO];
    }
    
    [service setUserCredentialsWithUsername:username password:password];
    
    return service;
}

#pragma mark -

- (void)fetchAllCalendars {
    LOG_CURRENT_METHOD;
    [self retain];
    
	GDataServiceGoogleCalendar *service = [self calendarService];
	[service fetchFeedWithURL:[NSURL URLWithString:kGDataGoogleCalendarDefaultAllCalendarsFeed]
					 delegate:self
			didFinishSelector:@selector(calendarListTicket:finishedWithFeed:error:)];
}

- (void)calendarListTicket:(GDataServiceTicket *)ticket
          finishedWithFeed:(GDataFeedCalendar *)feed
                     error:(NSError *)error {
    LOG_CURRENT_METHOD;
	if (!error) {
        NSArray *entries = [feed entries];
        
        GCKEventStore *eventStore = [GCKEventStore defaultEventStore];
        NSMutableArray *calendars = [NSMutableArray arrayWithCapacity:[entries count]];
        
        for (GDataEntryCalendar *entry in entries) {
            NSString *identifier = [entry identifier];
            NSString *title = [[entry title] stringValue];
            NSString *hex = [[entry color] stringValue];
            UIColor *color = [[[UIColor alloc] initWithHex:hex alpha:1.0f] autorelease];
            
            NSURL *feedURL = [[entry alternateLink] URL];
            NSString *tzName = [[entry timeZoneName] stringValue];
            NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:tzName];
            
            BOOL allowsContentModifications;
            NSString *accessLevel = [[entry accessLevel] stringValue];
            if ([accessLevel isEqualToString:kGDataCalendarAccessEditor] ||
                [accessLevel isEqualToString:kGDataCalendarAccessOwner] ||
                [accessLevel isEqualToString:kGDataCalendarAccessRoot]) {
                allowsContentModifications = YES;
            } else {
                allowsContentModifications = NO;
            }
            
            GCKCalendar *calendar = [eventStore calendarForIdentifier:identifier title:title color:color];
            calendar.feedURL = feedURL;
            calendar.timeZone = timeZone;
            calendar.accessLevel = accessLevel;
            calendar.allowsContentModifications = [NSNumber numberWithBool:allowsContentModifications];
            
            [calendars addObject:calendar];
            
            LOG(@"Retrieved Calendar: %@, %@", calendar.title, calendar.accessLevel);
        }
        
        GDataLink *nextLink = [feed nextLink];
        if (nextLink) {
            LOG(@"Fetch Next Link: %@", nextLink);
            GDataServiceGoogleCalendar *service = [self calendarService];
            [service fetchEntryWithURL:[nextLink URL] delegate:self didFinishSelector:@selector(calendarListTicket:finishedWithFeed:error:)];
            return;
        }
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  calendars, @"calendars",nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kCalendarsUpdatedNotification object:self userInfo:userInfo];
    } else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  error, @"error",nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kCalendarsUpdateFailedNotification object:self userInfo:userInfo];
    }
    
    [self autorelease];
}

#pragma mark -

- (void)fetchEventsForDateRange:(GCKDateRange *)dateRange calendar:(GCKCalendar *)calendar {
    GCKEventFetcher *fetcher = [GCKEventFetcher eventFetcherWithCalendar:calendar sync:self];
    [fetcher fetchEventsForDateRange:dateRange];
}

- (void)syncWithCalendar:(GCKCalendar *)calendar {
    GCKDateRange *dateRange = nil;
    
    NSDate *now = [NSDate date];
    NSDate *startDate = nil;
    NSDate *endDate = nil;
    
    NSCalendar *gregorianCalendar = [GCKGregorian gregorianCalendar];
//    
//    GCKGoogleCalendarSettingsSyncPeriod period = ((GCKGoogleCalendar *)calendar).settings.syncPeriod;
//    if (period == GCKGoogleCalendarSettingsSyncPeriod2WeeksBack) {
//        NSDateComponents *comps = [gregorianCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[now dateBySubtractingDays:14]];
//        [comps setDay:1];
//        startDate = [gregorianCalendar dateFromComponents:comps];
//    } else if (period == GCKGoogleCalendarSettingsSyncPeriod1MonthBack) {
        NSDateComponents *comps = [gregorianCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:now];
        [comps setDay:1];
        startDate = [gregorianCalendar dateFromComponents:comps];
        
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        [dateComponents setMonth:-1];
        
        startDate = [gregorianCalendar dateByAddingComponents:dateComponents toDate:startDate options:0];
        [dateComponents release];
//    } else if (period == GCKGoogleCalendarSettingsSyncPeriod3MonthsBack) {
//        NSDateComponents *comps = [gregorianCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:now];
//        [comps setDay:1];
//        startDate = [gregorianCalendar dateFromComponents:comps];
//        
//        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
//        [dateComponents setMonth:-3];
//        
//        startDate = [gregorianCalendar dateByAddingComponents:dateComponents toDate:startDate options:0];
//        [dateComponents release];
//    } else if (period == GCKGoogleCalendarSettingsSyncPeriod6MonthsBack) {
//        NSDateComponents *comps = [gregorianCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:now];
//        [comps setDay:1];
//        startDate = [gregorianCalendar dateFromComponents:comps];
//        
//        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
//        [dateComponents setMonth:-6];
//        
//        startDate = [gregorianCalendar dateByAddingComponents:dateComponents toDate:startDate options:0];
//        [dateComponents release];
//    }
    
    dateRange = [[[GCKDateRange alloc] initWithStartDate:startDate endDate:endDate] autorelease];
    
    [self fetchEventsForDateRange:dateRange calendar:calendar];
}

@end
