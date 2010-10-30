//
//  GCKRecurrenceEnd.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface GCKRecurrenceEnd :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSNumber * occurrenceCount;

+ (GCKRecurrenceEnd *)recurrenceEndWithDate:(NSDate *)date;

@end



