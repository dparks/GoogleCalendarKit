//
//  GCKDateRange.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCKDateRange : NSObject {
    NSDate *startDate;
    NSDate *endDate;
}

@property (nonatomic, readonly) NSDate *startDate;
@property (nonatomic, readonly) NSDate *endDate;

+ (GCKDateRange *)dateRangeWithDateToAfterAnHour:(NSDate *)occurrenceDate;
- (id)initWithStartDate:(NSDate *)start endDate:(NSDate *)end;
- (NSArray *)datesInRange;
+ (NSArray *)datesFromDate:(NSDate *)start toDate:(NSDate *)end;

@end
