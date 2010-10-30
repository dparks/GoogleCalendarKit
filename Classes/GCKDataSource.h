//
//  GCKDataSource.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kal.h"

@class GCKEventStore, GCKEvent;

@interface GCKDataSource : NSObject <KalDataSource> {
    NSMutableArray *items;
    NSMutableArray *events;
    GCKEventStore *eventStore;
}

+ (GCKDataSource *)dataSource;
- (GCKEvent *)eventAtIndexPath:(NSIndexPath *)indexPath;

@end
