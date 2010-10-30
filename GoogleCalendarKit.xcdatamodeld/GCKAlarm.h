//
//  GCKAlarm.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface GCKAlarm :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * absoluteDate;
@property (nonatomic, retain) NSNumber * relativeOffset;

@end



