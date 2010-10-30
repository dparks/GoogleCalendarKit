//
//  GCKRecurrenceRule.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef enum {
    GCKRecurrenceFrequencyDaily,
    GCKRecurrenceFrequencyWeekly,
    GCKRecurrenceFrequencyMonthly,
    GCKRecurrenceFrequencyYearly
} GCKRecurrenceFrequency;

enum {
    GCKSunday = 1,
    GCKMonday,
    GCKTuesday,
    GCKWednesday,
    GCKThursday,
    GCKFriday,
    GCKSaturday
};

@class GCKRecurrenceDayOfWeek;
@class GCKRecurrenceEnd;

@interface GCKRecurrenceRule :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * frequency;
@property (nonatomic, retain) id monthsOfTheYear;
@property (nonatomic, retain) NSNumber * firstDayOfTheWeek;
@property (nonatomic, retain) id daysOfTheYear;
@property (nonatomic, retain) id setPositions;
@property (nonatomic, retain) id daysOfTheMonth;
@property (nonatomic, retain) id weeksOfTheYear;
@property (nonatomic, retain) NSString * calendarIdentifier;
@property (nonatomic, retain) NSNumber * interval;
@property (nonatomic, retain) NSSet* daysOfTheWeek;
@property (nonatomic, retain) GCKRecurrenceEnd * recurrenceEnd;

+ (NSArray *)recurrenceOptions;
+ (GCKRecurrenceRule *)recurrenceWithFrequency:(GCKRecurrenceFrequency)type 
                                     interval:(NSInteger)interval 
                                daysOfTheWeek:(NSSet *)days 
                               daysOfTheMonth:(NSArray *)monthDays 
                              monthsOfTheYear:(NSArray *)months 
                               weeksOfTheYear:(NSArray *)weeksOfTheYear 
                                daysOfTheYear:(NSArray *)daysOfTheYear 
                                 setPositions:(NSArray *)setPositions end:(GCKRecurrenceEnd *)end;
+ (GCKRecurrenceRule *)recurrenceWithFrequency:(GCKRecurrenceFrequency)type 
                                     interval:(NSUInteger)interval 
                                          end:(GCKRecurrenceEnd *)end;
+ (GCKRecurrenceRule *)recurrenceWithRecurrence:(GCKRecurrenceRule *)rule;
- (NSString *)simpleDescription;

@end

@interface GCKRecurrenceRule (CoreDataGeneratedAccessors)
- (void)addDaysOfTheWeekObject:(GCKRecurrenceDayOfWeek *)value;
- (void)removeDaysOfTheWeekObject:(GCKRecurrenceDayOfWeek *)value;
- (void)addDaysOfTheWeek:(NSSet *)value;
- (void)removeDaysOfTheWeek:(NSSet *)value;

@end
