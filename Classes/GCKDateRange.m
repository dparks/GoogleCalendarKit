//
//  GCKDateRange.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKDateRange.h"
#import "GCKGregorian.h"
#import "DescriptionBuilder.h"
#import "NSDate+Additions.h"

static NSDateComponents *comps;

@implementation GCKDateRange

+ (void)initialize {
    comps = [[NSDateComponents alloc] init];
    [comps setDay:1];
}

+ (GCKDateRange *)dateRangeWithDateToAfterAnHour:(NSDate *)occurrenceDate {
    NSCalendar *gregorianCalendar = [GCKGregorian gregorianCalendar];
    
    NSDateComponents *occurrenceDateComponents = [gregorianCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate:occurrenceDate];
    
    NSDate *now = [NSDate date];
    NSDateComponents *nowDateComponents = [gregorianCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate:now];
    
    NSDateComponents *hourComponents = [[NSDateComponents alloc] init];
    [hourComponents setHour:1];
    
    NSDateComponents *startDateComponents = [gregorianCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate:occurrenceDate];
    [startDateComponents setHour:[nowDateComponents hour]];
    NSDate *sDate = [gregorianCalendar dateFromComponents:startDateComponents];
    
    sDate = [gregorianCalendar dateByAddingComponents:hourComponents toDate:sDate options:0];
    NSDate *endDate = [gregorianCalendar dateByAddingComponents:hourComponents toDate:sDate options:0];
    [hourComponents release];
    
    NSDateComponents *dateComponents = [gregorianCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate:sDate];
    [dateComponents setDay:[occurrenceDateComponents day]];
    
    NSDate *startDate = [gregorianCalendar dateFromComponents:dateComponents];
    
    GCKDateRange *dateRange = [[GCKDateRange alloc] initWithStartDate:startDate endDate:endDate];
    return [dateRange autorelease];
}

- (id)initWithStartDate:(NSDate *)start endDate:(NSDate *)end {
    if ((self = [super init])) {
        startDate = [start copy];
        endDate = [end copy];
    }
    return self;
}

- (void)dealloc {
    [startDate release];
    [endDate release];
    [super dealloc];
}

- (NSArray *)datesInRange {
    NSMutableArray *dates = [NSMutableArray array];
    NSCalendar *gregorianCalendar = [GCKGregorian gregorianCalendar];
    NSDate *date = [startDate dateByTruncatingTimes];
    while ([date compare:endDate] != NSOrderedDescending) {
        [dates addObject:date];
        date = [gregorianCalendar dateByAddingComponents:comps toDate:date options:0];
    }
    return dates;
}

+ (NSArray *)datesFromDate:(NSDate *)start toDate:(NSDate *)end {
    NSMutableArray *dates = [NSMutableArray array];
    NSCalendar *gregorianCalendar = [GCKGregorian gregorianCalendar];
    NSDate *date = [start dateByTruncatingTimes];
    while ([date compare:end] != NSOrderedDescending) {
        [dates addObject:date];
        date = [gregorianCalendar dateByAddingComponents:comps toDate:date options:0];
    }
    return dates;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - %@", startDate, endDate];
}

@end
