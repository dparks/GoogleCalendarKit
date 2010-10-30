//
//  GCKOriginalEvent.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface GCKOriginalEvent :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * eventIdentifier;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSNumber * isCanceled;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSString * originalID;

@end



