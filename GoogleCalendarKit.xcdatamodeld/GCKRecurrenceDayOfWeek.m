// 
//  GCKRecurrenceDayOfWeek.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKRecurrenceDayOfWeek.h"
#import "GoogleCalendarKitAppDelegate.h"

@implementation GCKRecurrenceDayOfWeek 

@dynamic dayOfTheWeek;
@dynamic weekNumber;

+ (GCKRecurrenceDayOfWeek *)dayOfWeek:(NSInteger)dayWeek {
    GoogleCalendarKitAppDelegate *app = (GoogleCalendarKitAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [app managedObjectContext];
    
    GCKRecurrenceDayOfWeek *dayOfWeek = [NSEntityDescription insertNewObjectForEntityForName:@"RecurrenceDayOfWeek" inManagedObjectContext:context];
    dayOfWeek.dayOfTheWeek = [NSNumber numberWithInteger:dayWeek];
    
    return dayOfWeek;
}

+ (id)dayOfWeek:(NSInteger)dayWeek weekNumber:(NSInteger)week {
    GCKRecurrenceDayOfWeek *dayOfWeek = [self dayOfWeek:dayWeek];
    dayOfWeek.weekNumber = [NSNumber numberWithInteger:week];
    return dayOfWeek;
}

@end
