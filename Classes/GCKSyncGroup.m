//
//  GCKSyncGroup.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKSyncGroup.h"

NSString * const kSyncGroupStartedNotification = @"kSyncGroupStartedNotification";
NSString * const kSyncGroupFinishedNotification = @"kSyncGroupFinishedNotification";

@implementation GCKSyncGroup

+ (GCKSyncGroup *)syncGroup {
    return [[[GCKSyncGroup alloc] init] autorelease];
}

- (id)init {
    if ((self = [super init])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncFinished:) name:kCalendarSyncFinishedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncFinished:) name:kCalendarSyncFailedNotification object:nil];
        syncGroup = [[NSMutableArray alloc] init];
        calendars = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    LOG_CURRENT_METHOD;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [syncGroup release];
    [calendars release];
    [super dealloc];
}

- (void)addSync:(GCKSync *)sync calendar:(GCKCalendar *)calendar {
    [syncGroup addObject:sync];
    [calendars addObject:calendar];
}

- (void)start {
    if ([syncGroup count] > 0) {
        [self retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:kSyncGroupStartedNotification object:self];
        
        GCKSync *sync = [syncGroup lastObject];
        [sync syncWithCalendar:[calendars lastObject]];
    }
}

- (void)syncFinished:(NSNotification *)note {
    [syncGroup removeLastObject];
    [calendars removeLastObject];
    if ([syncGroup count] > 0) {
        GCKSync *sync = [syncGroup lastObject];
        [sync syncWithCalendar:[calendars lastObject]];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSyncGroupFinishedNotification object:self];
        [self autorelease];
    }
}

@end
