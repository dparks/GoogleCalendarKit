//
//  NSDate+Additions.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/08/25.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "NSDate+Additions.h"

#define D_MINUTE 60
#define D_HOUR 3600
#define D_DAY 86400
#define D_WEEK 604800
#define D_YEAR 31556926

@implementation NSDate(Additions)

+ (NSDate *)dateWithMinutes:(NSUInteger)minutes before:(NSDate *)date  {
	NSTimeInterval timeInterval = [date timeIntervalSinceReferenceDate] - D_MINUTE * minutes;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:timeInterval];
	return newDate;		
}

- (NSDate *)dateByAddingDays:(NSInteger)dDays {
	NSTimeInterval aTimeInterval = [self timeIntervalSinceReferenceDate] + D_DAY * dDays;
	NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
	return newDate;		
}

- (NSDate *)dateBySubtractingDays:(NSInteger)dDays {
	return [self dateByAddingDays:(dDays * -1)];
}

- (NSDate *)dateByTruncatingTimes {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:
                                        NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
	return [calendar dateFromComponents:dateComponents];
}

- (NSInteger)daysAfterDate:(NSDate *)aDate {
	NSTimeInterval ti = [self timeIntervalSinceDate:aDate];
	return (NSInteger) (ti / D_DAY);
}

- (NSInteger)daysBeforeDate:(NSDate *)aDate {
	NSTimeInterval ti = [aDate timeIntervalSinceDate:self];
	return (NSInteger) (ti / D_DAY);
}

@end
