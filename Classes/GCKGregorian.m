//
//  GCKGregorian.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKGregorian.h"

static NSCalendar *gregorianCalendar;

@implementation GCKGregorian

+ (void)initialize {
    gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorianCalendar setFirstWeekday:1];
    [gregorianCalendar setMinimumDaysInFirstWeek:1];
}

+ (NSCalendar *)gregorianCalendar {
    return gregorianCalendar;
}

@end
