//
//  GCKSettingViewController.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GCKSettingViewController : UITableViewController<UITextFieldDelegate> {
    UIActivityIndicatorView *activityIndicator;
    UITextField *usernameField;
    UITextField *passwordField;
    UILabel *updateLabel;
    
    NSArray *calendars;
}

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UITextField *usernameField;
@property (nonatomic, retain) UITextField *passwordField;
@property (nonatomic, retain) UILabel *updateLabel;

@property (nonatomic, retain) NSArray *calendars;

- (void)updateCalendar;

@end
