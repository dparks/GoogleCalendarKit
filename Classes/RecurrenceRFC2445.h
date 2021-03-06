//  RecurrenceRFC2445.h
//
/* Copyright (c) 2008 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#undef EXTERN
#undef INITIALIZE_AS
#ifdef RECURRENCE_RFC2445_DEFINE_GLOBALS
#define EXTERN 
#define INITIALIZE_AS(x) =x
#else
#define EXTERN extern
#define INITIALIZE_AS(x)
#endif

#import <Foundation/Foundation.h>

@class GDataDateTime;

EXTERN NSString * const kStartDateKey INITIALIZE_AS(@"start date");

EXTERN NSString * const kEndDateKey INITIALIZE_AS(@"end date");

EXTERN NSString * const kExceptionDatesKey INITIALIZE_AS(@"exception dates");

// Recurrence keys
// See: the section of following URL on Recurrence.
// http://developer.apple.com/documentation/AppleApplications/Reference/SyncServicesSchemaRef/Articles/Calendars.html

// NSArray of NSString representing the days of the week on which this
// recurrence occurs. Possible string values are sunday, monday, tuesday,
// wednesday, thursday, friday, and saturday. If you set bydaydays, you must
// also set bydayfreq. For example, if bydaydays is monday and bydayfreq
// contains 0, then the recurrence is every Monday.
EXTERN NSString * const kRecurrenceByDayDays INITIALIZE_AS(@"bydaydays");

// NSArray of NSNumber used in combination with bydaydays to specify which week
// within a month or year this recurrence occurs. For example, if frequency is
// monthly, bydaydays is monday and bydayfreq contains 2, then the recurrence
// will occur the second Monday of every month.
EXTERN NSString * const kRecurrenceByDayFreq INITIALIZE_AS(@"bydayfreq");

// NSArray of NSNumber ranging from 1 to 12, that indicate the months within a
// year that this recurrence occurs.
EXTERN NSString * const kRecurrenceByMonth INITIALIZE_AS(@"bymonth");

// NSArray of NSNumber ranging from 1 to 31 or -31 to -1, that indicate the days
// within a month that this recurrence occurs. Negative values indicate the
// number of days from the last day of the month.
EXTERN NSString * const kRecurrenceByMonthDay INITIALIZE_AS(@"bymonthday");

// NSArray of NSNumber used to specify specific days within an expanded set of
// occurrences. The numbers specify the index of an expanded sequence of
// occurrences starting with 1. For example, if frequency is daily, the event or
// task starts on a Monday, and bysetpos is (1, 8), then the recurrence will
// occur on the first and second Mondays only. If bysetpos is (2, 8) the event
// or task will occur on the first Tuesday in the sequence and the second
// Monday.
EXTERN NSString * const kRecurrenceBySetPos INITIALIZE_AS(@"bysetpos");

// NSArray of NSNumber ranging from 1 to 53 or -53 to -1
// that indicate the weeks within a year that this recurrence occurs.
// Negative values indicate the number of weeks from the last week of the year.
EXTERN NSString * const kRecurrenceByWeekNumber INITIALIZE_AS(@"byweeknumber");

// NSArray of NSNumber ranging from 1 to 366 or -366 to -1, 
// that indicate the days within a year that this recurrence occurs. 
// Negative values indicate the number of days from the last day of the year.
EXTERN NSString * const kRecurrenceByYearDay INITIALIZE_AS(@"byyearday");

// NSNumber of occurrences generated by this recurrence.
EXTERN NSString * const kRecurrenceCountKey INITIALIZE_AS(@"count");

// NSString frequency of this recurrence specified by a constant. 
// Possible values are daily, weekly, monthly, or yearly
EXTERN NSString * const kRecurrenceFrequencyKey  INITIALIZE_AS(@"frequency");

// NSNumber frequency of this recurrence specified by days.
// For example, 2 indicates a frequency of every two days.
EXTERN NSString * const kRecurrenceIntervalKey INITIALIZE_AS(@"interval");

// NSCalendarDate The end date of this recurrence.
EXTERN NSString * const kRecurrenceUntilKey INITIALIZE_AS(@"until");

// NSString indicates the start day of the week. 
// Possible values are sunday, monday, tuesday, wednesday, thursday, friday, and saturday.
EXTERN NSString * const kRecurrenceWeekStartDayKey INITIALIZE_AS(@"weekstartday");

// NSNumber NSTimeInterval seconds.
// This key is not used by SyncServices, but is by rfc2445.txt
EXTERN NSString * const kRecurrenceDurationKey INITIALIZE_AS(@"duration");

#define kSecondsInMinute 60
#define kSecondsInHour (kSecondsInMinute * 60)
#define kSecondsInDay (kSecondsInHour * 24)
#define kSecondsInWeek (kSecondsInDay * 7)

/// Map from the RFC2445 spec. for a recurring event to Sync Services and back.
// See http://www.ietf.org/rfc/rfc2445.txt
@interface RecurrenceRFC2445 : NSObject {
@private
    NSScanner           *srcScanner_; // STRONG
    NSMutableDictionary *val_; // STRONG result of parsing
    NSTimeZone          *timeZone_; // STRONG
}
+ (RecurrenceRFC2445 *)recurrence;

/// mutable because it may include a kStartDate, which we must not pass to iCal.app
- (NSMutableDictionary *)recurrenceDictionaryFromString:(NSString *)recurrenceS;

- (GDataDateTime *)asGDataDateTime:(id)date;
- (NSString *)recurrenceStringFromDictionary:(NSDictionary *)dictS;

/// Generate a RecurrenceRFC2445 format string from a dictionary, such as above. 
// Allow optional starttime, endtime, or exceptions to be passed in. 
// Convenience for a dict that has kStartDateKey and kEndDateKey keys already
- (NSString *)recurrenceStringFromDictionary:(NSDictionary *)dictS 
                                   startDate:(GDataDateTime *)startDate 
                                     endDate:(GDataDateTime *)endDate
                              exceptionDates:(NSArray *)exceptions; // of GDataDateTime

- (NSString *)recurrenceStringRuleFromDictionary:(NSDictionary *)dictS;
- (NSString *)recurrenceString:(NSString *)verb forDate:(GDataDateTime *)date;

@end

NSString *RecurrenceStringFromDate(id arg);
NSString *RecurrenceStringNoZoneFromDate(id arg);
