//
//  GCKCalendar.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef enum {
    GCKCalendarTypeLocal,
    GCKCalendarTypeCalDAV,
    GCKCalendarTypeExchange,
    GCKCalendarTypeSubscription,
    GCKCalendarTypeBirthday
} GCKCalendarType;

enum {
    GCKCalendarEventAvailabilityNone         = 0,
    GCKCalendarEventAvailabilityBusy         = (1 << 0),
    GCKCalendarEventAvailabilityFree         = (1 << 1),
    GCKCalendarEventAvailabilityTentative    = (1 << 2),
    GCKCalendarEventAvailabilityUnavailable  = (1 << 3),
};

@interface GCKCalendar :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * showsCalendar;
@property (nonatomic, retain) NSNumber * supportedEventAvailabilities;
@property (nonatomic, retain) NSNumber * syncEnabled;
@property (nonatomic, retain) UIColor * color;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * allowsContentModifications;
@property (nonatomic, retain) NSTimeZone * timeZone;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * accessLevel;
@property (nonatomic, retain) NSURL * feedURL;
@property (nonatomic, retain) NSNumber * syncPeriod;
@property (nonatomic, retain) NSString * calendarIdentifier;
@property (nonatomic, retain) NSDate * lastSyncedDate;

@end
