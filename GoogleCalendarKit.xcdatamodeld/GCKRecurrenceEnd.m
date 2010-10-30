// 
//  GCKRecurrenceEnd.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKRecurrenceEnd.h"
#import "GoogleCalendarKitAppDelegate.h"

@implementation GCKRecurrenceEnd 

@dynamic endDate;
@dynamic occurrenceCount;

+ (GCKRecurrenceEnd *)recurrenceEndWithDate:(NSDate *)date {
    GoogleCalendarKitAppDelegate *app = (GoogleCalendarKitAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [app managedObjectContext];
    
    GCKRecurrenceEnd *recurrenceEnd = [NSEntityDescription insertNewObjectForEntityForName:@"RecurrenceEnd" inManagedObjectContext:context];
    recurrenceEnd.endDate = date;
    
    return recurrenceEnd;
}

@end
