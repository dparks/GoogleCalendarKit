//
//  GCKRecurrenceDayOfWeek.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface GCKRecurrenceDayOfWeek :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * dayOfTheWeek;
@property (nonatomic, retain) NSNumber * weekNumber;

+ (id)dayOfWeek:(NSInteger)dayOfTheWeek;
+ (id)dayOfWeek:(NSInteger)dayOfTheWeek weekNumber:(NSInteger)weekNumber;

@end



