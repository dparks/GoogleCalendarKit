//
//  GCKDataSource.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKDataSource.h"
#import "GCKEventStore.h"
#import "GCKEvent.h"
#import "GCKDateRange.h"
#import "GCKSync.h"

static BOOL IsDateBetweenInclusive(NSDate *date, NSDate *begin, NSDate *end) {
    return [date compare:begin] != NSOrderedAscending && [date compare:end] != NSOrderedDescending;
}

@interface GCKDataSource ()
- (NSArray *)eventsFrom:(NSDate *)fromDate to:(NSDate *)toDate;
- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate;
@end

@implementation GCKDataSource

+ (GCKDataSource *)dataSource {
    return [[[GCKDataSource alloc] init] autorelease];
}

- (id)init {
    if ((self = [super init])) {
        eventStore = [GCKEventStore defaultEventStore];
        events = [[NSMutableArray alloc] init];
        items = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventUpdated:) name:kEventsUpdatedNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [items release];
    [events release];
    [super dealloc];
}

- (void)eventUpdated:(NSNotification *)note {
    [[NSNotificationCenter defaultCenter] postNotificationName:KalDataSourceChangedNotification object:nil];
}

- (GCKEvent *)eventAtIndexPath:(NSIndexPath *)indexPath {
    return [items objectAtIndex:indexPath.row];
}

#pragma mark -

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"MyCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    GCKEvent *event = [self eventAtIndexPath:indexPath];
    cell.textLabel.text = event.title;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [items count];
}

#pragma mark -

- (void)presentingDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate delegate:(id<KalDataSourceCallbacks>)delegate {
    [events removeAllObjects];
    NSLog(@"Fetching events from EventKit between %@ and %@", fromDate, toDate);
    
    GCKDateRange *dateRange = [[GCKDateRange alloc] initWithStartDate:fromDate endDate:toDate];
    NSArray *matchedEvents = [eventStore eventsMatchingDateRange:dateRange];
    [dateRange release];
    
    [events addObjectsFromArray:matchedEvents];
    [delegate loadedDataSource:self];
}

- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate {
    return [[self eventsFrom:fromDate to:toDate] valueForKeyPath:@"startDate"];
}

- (void)loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    [items addObjectsFromArray:[self eventsFrom:fromDate to:toDate]];
}

- (void)removeAllItems {
    [items removeAllObjects];
}

#pragma mark -

- (NSArray *)eventsFrom:(NSDate *)fromDate to:(NSDate *)toDate {
    NSMutableArray *matches = [NSMutableArray array];
    for (GCKEvent *event in events)
        if (IsDateBetweenInclusive(event.startDate, fromDate, toDate))
            [matches addObject:event];
    
    return matches;
}

@end
