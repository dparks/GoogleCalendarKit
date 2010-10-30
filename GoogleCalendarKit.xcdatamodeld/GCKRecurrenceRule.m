// 
//  GCKRecurrenceRule.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKRecurrenceRule.h"
#import "GCKRecurrenceDayOfWeek.h"
#import "GCKRecurrenceEnd.h"
#import "GoogleCalendarKitAppDelegate.h"

static NSArray *recurrenceOptions;
static NSArray *recurrenceLocalizations;

@implementation GCKRecurrenceRule 

@dynamic frequency;
@dynamic monthsOfTheYear;
@dynamic firstDayOfTheWeek;
@dynamic daysOfTheYear;
@dynamic setPositions;
@dynamic daysOfTheMonth;
@dynamic weeksOfTheYear;
@dynamic calendarIdentifier;
@dynamic interval;
@dynamic daysOfTheWeek;
@dynamic recurrenceEnd;

+ (void)initialize {
    recurrenceOptions = [[NSArray alloc] initWithObjects:
                         NSLocalizedString(@"None", nil),
                         NSLocalizedString(@"Every Day", nil),
                         NSLocalizedString(@"Every Week", nil),
                         NSLocalizedString(@"Every 2 Weeks", nil),
                         NSLocalizedString(@"Every Month", nil),
                         NSLocalizedString(@"Every Year", nil), nil];
    recurrenceLocalizations = [[NSArray alloc] initWithObjects:
                               NSLocalizedString(@"Never", nil),
                               NSLocalizedString(@"Daily", nil),
                               NSLocalizedString(@"Weekly", nil),
                               NSLocalizedString(@"Biweekly", nil),
                               NSLocalizedString(@"Monthly", nil),
                               NSLocalizedString(@"Yearly", nil), nil];
}

+ (NSArray *)recurrenceOptions {
    return recurrenceOptions;
}

/*
 type
 The frequency of the recurrence rule. Can be daily, weekly, monthly, or yearly.
 interval
 The interval between instances of this recurrence. For example, a weekly recurrence rule with an interval of 2 occurs every other week. Must be greater than 0.
 days
 The days of the week that the event occurs, as an array of EKRecurrenceDayOfWeek objects.
 monthDays
 The days of the month that the event occurs, as an array of NSNumber objects. Values can be from 1 to 31 and from -1 to -31. This parameter is only valid for recurrence rules of type EKMonthlyRecurrence.
 months
 The months of the year that the event occurs, as an array of NSNumber objects. Values can be from 1 to 12. This parameter is only valid for recurrence rules of type EKYearlyOccurrence.
 weeksOfTheYear
 The weeks of the year that the event occurs, as an array of NSNumber objects. Values can be from 1 to 53 and from -1 to -53. This parameter is only valid for recurrence rules of type EKYearlyOccurrence.
 daysOfTheYear
 The days of the year that the event occurs, as an array of NSNumber objects. Values can be from 1 to 366 and from -1 to -366. This parameter is only valid for recurrence rules of type EKYearlyOccurrence.
 setPositions
 An array of ordinal numbers that filters which recurrences to include in the recurrence rule’s frequency. See setPositions for more information.
 end
 The end of the recurrence rule.
 */
+ (GCKRecurrenceRule *)recurrenceWithFrequency:(GCKRecurrenceFrequency)type 
                                     interval:(NSInteger)intvl 
                                daysOfTheWeek:(NSSet *)days 
                               daysOfTheMonth:(NSArray *)monthDays 
                              monthsOfTheYear:(NSArray *)months 
                               weeksOfTheYear:(NSArray *)weeksYear 
                                daysOfTheYear:(NSArray *)daysYear 
                                 setPositions:(NSArray *)positions 
                                          end:(GCKRecurrenceEnd *)end {
    GoogleCalendarKitAppDelegate *app = (GoogleCalendarKitAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [app managedObjectContext];
    
    GCKRecurrenceRule *recurrenceRule = [NSEntityDescription insertNewObjectForEntityForName:@"RecurrenceRule" inManagedObjectContext:context];
    recurrenceRule.frequency = [NSNumber numberWithInteger:type];
    recurrenceRule.interval = [NSNumber numberWithInteger:intvl];
    if (days) {
        [recurrenceRule addDaysOfTheWeek:days];
    }
    recurrenceRule.daysOfTheMonth = monthDays;
    recurrenceRule.monthsOfTheYear = months;
    recurrenceRule.weeksOfTheYear = weeksYear;
    recurrenceRule.daysOfTheYear = daysYear;
    recurrenceRule.setPositions = positions;
    recurrenceRule.recurrenceEnd = end;
    
    return recurrenceRule;
}

+ (GCKRecurrenceRule *)recurrenceWithFrequency:(GCKRecurrenceFrequency)type 
                                     interval:(NSUInteger)intvl 
                                          end:(GCKRecurrenceEnd *)end {
    return [GCKRecurrenceRule recurrenceWithFrequency:type interval:intvl daysOfTheWeek:nil daysOfTheMonth:nil monthsOfTheYear:nil weeksOfTheYear:nil daysOfTheYear:nil setPositions:nil end:end];
}

+ (GCKRecurrenceRule *)recurrenceWithRecurrence:(GCKRecurrenceRule *)rule {
    GoogleCalendarKitAppDelegate *app = (GoogleCalendarKitAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [app managedObjectContext];
    
    GCKRecurrenceRule *recurrenceRule = [NSEntityDescription insertNewObjectForEntityForName:@"RecurrenceRule" inManagedObjectContext:context];
    recurrenceRule.frequency = rule.frequency;
    recurrenceRule.interval = rule.interval;
    NSSet *days = rule.daysOfTheWeek;
    for (GCKRecurrenceDayOfWeek *dotw in days) {
        GCKRecurrenceDayOfWeek *d = [GCKRecurrenceDayOfWeek dayOfWeek:[dotw.dayOfTheWeek integerValue] weekNumber:[dotw.weekNumber integerValue]];
        [recurrenceRule addDaysOfTheWeekObject:d];
    }
    recurrenceRule.daysOfTheMonth = rule.daysOfTheMonth;
    recurrenceRule.monthsOfTheYear = rule.monthsOfTheYear;
    recurrenceRule.weeksOfTheYear = rule.weeksOfTheYear;
    recurrenceRule.daysOfTheYear = rule.daysOfTheYear;
    recurrenceRule.setPositions = rule.setPositions;
    if (rule.recurrenceEnd) {
        recurrenceRule.recurrenceEnd = [GCKRecurrenceEnd recurrenceEndWithDate:rule.recurrenceEnd.endDate];
    }
    
    return recurrenceRule;
}

- (NSString *)simpleDescription {
    NSString *description = nil;
    GCKRecurrenceFrequency freq = [self.frequency integerValue];
    NSInteger intvl = [self.interval integerValue];
    if (freq == GCKRecurrenceFrequencyDaily) {
        description = [recurrenceLocalizations objectAtIndex:1];
    } else if (freq == GCKRecurrenceFrequencyWeekly && intvl == 2) {
        description = [recurrenceLocalizations objectAtIndex:3];
    } else if (freq == GCKRecurrenceFrequencyWeekly) {
        description = [recurrenceLocalizations objectAtIndex:2];
    } else if (freq == GCKRecurrenceFrequencyMonthly) {
        description = [recurrenceLocalizations objectAtIndex:4];
    } else if (freq == GCKRecurrenceFrequencyYearly) {
        description = [recurrenceLocalizations objectAtIndex:5];
    }
    return description;
}

@end
