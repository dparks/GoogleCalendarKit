//
//  NSDate+Additions.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/08/25.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate(Additions) 
+ (NSDate *)dateWithMinutes:(NSUInteger)minutes before:(NSDate *)date;
- (NSDate *)dateByAddingDays:(NSInteger)dDays;
- (NSDate *)dateBySubtractingDays:(NSInteger)dDays;
- (NSDate *)dateByTruncatingTimes;
- (NSInteger)daysAfterDate:(NSDate *)aDate;
- (NSInteger)daysBeforeDate:(NSDate *)aDate;
@end
