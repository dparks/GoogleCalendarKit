//
//  GCKCalendarCell.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GCKCalendarCell : UITableViewCell {
    UIView *cellContentView;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) UIColor *color;
@property (nonatomic, assign) BOOL selectable;
@property (nonatomic, retain) NSString *syncState;

@end
