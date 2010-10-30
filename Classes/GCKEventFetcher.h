//
//  GCKEventFetcher.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GCKSync, GCKCalendar, GCKDateRange;

@interface GCKEventFetcher : NSObject {
    GCKCalendar *calendar;
    GCKSync *sync;
}

@property (nonatomic, retain) GCKCalendar *calendar;
@property (nonatomic, retain) GCKSync *sync;

+ (GCKEventFetcher *)eventFetcherWithCalendar:(GCKCalendar *)calendar 
                                         sync:(GCKSync *)sync;
- (void)fetchEventsForDateRange:(GCKDateRange *)dateRange;

@end
