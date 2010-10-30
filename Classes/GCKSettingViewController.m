//
//  GCKSettingViewController.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKSettingViewController.h"
#import "GCKCalendarCell.h"
#import "GCKSync.h"
#import "GCKEventStore.h"
#import "GCKCalendar.h"
#import "UIColor+Additions.h"

@implementation GCKSettingViewController

- (id)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarsUpdated:) name:kCalendarsUpdatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarsUpdateFailed:) name:kCalendarsUpdateFailedNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.activityIndicator = nil;
    self.usernameField = nil;
    self.passwordField = nil;
    self.updateLabel = nil;
    self.calendars = nil;
    [super dealloc];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Google Calendar", nil);
    self.clearsSelectionOnViewWillAppear = YES;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    [doneButton release];
    
    GCKEventStore *eventStore = [GCKEventStore defaultEventStore];
    self.calendars = [eventStore allCalendars];
    
    self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    activityIndicator.hidesWhenStopped = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:@"username"];
    NSString *password = [defaults objectForKey:@"password"];
    
    self.usernameField = [[[UITextField alloc] initWithFrame:CGRectMake(20.0f, 12.0f, 280.0f, 24.0f)] autorelease];
    usernameField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    usernameField.delegate = self;
    usernameField.adjustsFontSizeToFitWidth = NO;
    usernameField.borderStyle = UITextBorderStyleNone;
    usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    usernameField.clearsOnBeginEditing = NO;
    usernameField.enablesReturnKeyAutomatically = YES;
    usernameField.returnKeyType = UIReturnKeyNext;
    usernameField.placeholder = NSLocalizedString(@"example@gmail.com", nil);
    usernameField.keyboardType = UIKeyboardTypeEmailAddress;
    usernameField.font = [UIFont systemFontOfSize:17.0f];
    usernameField.text = username;
    [usernameField addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    
    self.passwordField = [[[UITextField alloc] initWithFrame:CGRectMake(20.0f, 12.0f, 280.0f, 24.0f)] autorelease];
    passwordField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    passwordField.delegate = self;
    passwordField.adjustsFontSizeToFitWidth = NO;
    passwordField.borderStyle = UITextBorderStyleNone;
    passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    passwordField.clearsOnBeginEditing = NO;
    passwordField.enablesReturnKeyAutomatically = YES;
    passwordField.returnKeyType = UIReturnKeyDone;
    passwordField.placeholder = NSLocalizedString(@"Password", nil);
    passwordField.keyboardType = UIKeyboardTypeASCIICapable;
    passwordField.font = [UIFont systemFontOfSize:17.0f];
    passwordField.secureTextEntry = YES;
    passwordField.text = password;
    [passwordField addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    
    self.updateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 0.0f, 320.0f, 44.0f)];
    updateLabel.backgroundColor = [UIColor clearColor];
    updateLabel.adjustsFontSizeToFitWidth = NO;
    updateLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    updateLabel.highlightedTextColor = [UIColor whiteColor];
    if ([calendars count] > 0) {
        updateLabel.text = NSLocalizedString(@"Update Calendar", nil);
    } else {
        updateLabel.text = NSLocalizedString(@"Retrieve Calendar", nil);
    }
    updateLabel.textAlignment = UITextAlignmentCenter;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark -

- (void)done:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [calendars count] + 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    } else if (section == 1) {
        return 1;
    } else {
        return 3;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;
    
    if (section == 0 && row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UsernameCell"];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UsernameCell"] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            [cell addSubview:usernameField];
        }
        
        return cell;
    } else if (section == 0 && row == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PasswordCell"];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PasswordCell"] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            [cell addSubview:passwordField];
        }
        
        return cell;
    } else if (section == 1 && row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UpdateCell"];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UpdateCell"] autorelease];            
            [cell addSubview:updateLabel];
            cell.accessoryView = activityIndicator;
        }
        
        if (![activityIndicator isAnimating] && [usernameField.text length] > 0 && [passwordField.text length] > 0) {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            updateLabel.textColor = [UIColor settingTextColor];
        } else {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            updateLabel.textColor = [UIColor grayColor];
        }
        
        return cell;
    } else {
        GCKCalendar *calendar = [calendars objectAtIndex:section - 2];
        if (row == 0) {
            GCKCalendarCell *cell = (GCKCalendarCell *)[tableView dequeueReusableCellWithIdentifier:@"CalendarCell"];
            if (cell == nil) {
                cell = [[[GCKCalendarCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CalendarCell"] autorelease];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            cell.title = calendar.title;
            cell.color = calendar.color;
//            cell.syncState = [calendar syncStateDescription];
            
            return cell;
        }  else if (row == 1) {
            NSString *cellIdentifier = [NSString stringWithFormat:@"SyncEnabledCell%d", section];
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                UISwitch *syncSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(206.0f, 8.0f, 94.0f, 27.0f)];
                syncSwitch.tag = 10;
                [syncSwitch addTarget:self action:@selector(syncSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                [cell addSubview:syncSwitch];
                [syncSwitch release];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Sync", nil);
            
            UISwitch *syncSwitch = (UISwitch *)[cell viewWithTag:10];
            if (syncSwitch) {
                syncSwitch.on = [calendar.syncEnabled boolValue];
            }
            
            return cell;
        } else {
            NSString *cellIdentifier = [NSString stringWithFormat:@"SyncPeriodCell%d", section];
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            cell.textLabel.text = NSLocalizedString(@"Period", nil);
            
            UILabel *syncPeriodLabel = (UILabel *)[cell viewWithTag:10];
            if (!syncPeriodLabel) {
                syncPeriodLabel = [[UILabel alloc] initWithFrame:CGRectMake(40.0f, 12.0f, 240.0f, 21.0f)];
                syncPeriodLabel.tag = 10;
                syncPeriodLabel.backgroundColor = [UIColor clearColor];
                syncPeriodLabel.textColor = [UIColor settingTextColor];
                syncPeriodLabel.highlightedTextColor = [UIColor whiteColor];
                syncPeriodLabel.textAlignment = UITextAlignmentRight;
                
                [cell addSubview:syncPeriodLabel];
                [syncPeriodLabel release];
            }
            
//            SPGoogleCalendarSettingsSyncPeriod period = calendar.settings.syncPeriod;
//            if (period == SPGoogleCalendarSettingsSyncPeriod2WeeksBack) {
//                syncPeriodLabel.text = NSLocalizedString(@"Events 2 Weeks Back", nil);
//            } else if (period == SPGoogleCalendarSettingsSyncPeriod1MonthBack) {
//                syncPeriodLabel.text = NSLocalizedString(@"Events 1 Month Back", nil);
//            } else if (period == SPGoogleCalendarSettingsSyncPeriod3MonthsBack) {
//                syncPeriodLabel.text = NSLocalizedString(@"Events 3 Months Back", nil);
//            } else if (period == SPGoogleCalendarSettingsSyncPeriod6MonthsBack) {
//                syncPeriodLabel.text = NSLocalizedString(@"Events 6 Months Back", nil);
//            } else {
//                syncPeriodLabel.text = NSLocalizedString(@"All Events", nil);
//            }
            
            return cell;
        }
    }
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = indexPath.row;
    NSUInteger section = indexPath.section;
    
    if (section == 1) {
        if (![activityIndicator isAnimating] && [usernameField.text length] > 0 && [passwordField.text length] > 0) {
            updateLabel.textColor = [UIColor grayColor];
            [self updateCalendar];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    } else if (section >= 2) {
        GCKCalendar *calendar = [calendars objectAtIndex:section - 2];
        if (row == 0) {
//            GCKCalendarSyncViewController *controller = [[GCKCalendarSyncViewController alloc] init];
//            controller.delegate = self;
//            controller.calendar = calendar;
//            [self.navigationController pushViewController:controller animated:YES];
//            [controller release];
        } else if (row == 2) {
//            GCKCalendarSyncPeriodViewController *controller = [[GCKCalendarSyncPeriodViewController alloc] init];
//            controller.calendar = calendar;
//            [self.navigationController pushViewController:controller animated:YES];
//            [controller release];
        }
    }
}

#pragma mark -

- (void)calendarsUpdated:(NSNotification *)note {
    LOG_CURRENT_METHOD;
    NSDictionary *userInfo = [note userInfo];
    
    self.calendars = [userInfo objectForKey:@"calendars"];
    
    NSString *username = usernameField.text;
    NSString *password = passwordField.text;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:username forKey:@"username"];
    [defaults setObject:password forKey:@"password"];
    
    [defaults synchronize];
    
    if ([calendars count] > 0) {
        updateLabel.text = NSLocalizedString(@"Update Calendar", nil);
    } else {
        updateLabel.text = NSLocalizedString(@"Retrieve Calendar", nil);
    }
    
    [activityIndicator stopAnimating];
    usernameField.enabled = YES;
    passwordField.enabled = YES;
    
    [self.tableView reloadData];
}

- (void)calendarsUpdateFailed:(NSNotification *)note {
    LOG_CURRENT_METHOD;
    NSError *error = [[note userInfo] objectForKey:@"error"];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *infoDictionary = [bundle localizedInfoDictionary];
    NSString *appName = [[infoDictionary count] ? infoDictionary : [bundle infoDictionary] objectForKey:@"CFBundleName"];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:appName
                                                    message:[error localizedDescription]
                                                   delegate:nil 
                                          cancelButtonTitle:nil 
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    [alert show];
    [alert release];
    
    [activityIndicator stopAnimating];
    usernameField.enabled = YES;
    passwordField.enabled = YES;
    
    [self.tableView reloadData];
}

#pragma mark -

- (void)updateCalendar {
    [activityIndicator startAnimating];
    usernameField.enabled = NO;
    passwordField.enabled = NO;
    
    NSString *username = usernameField.text;
    NSString *password = passwordField.text;
    
    GCKSync *sync = [GCKSync syncWithUsername:username password:password];
    [sync fetchAllCalendars];
}

#pragma mark -

- (void)syncSwitchChanged:(id)sender {
    UISwitch *syncSwitch = (UISwitch *)sender;
    UITableViewCell *cell = (UITableViewCell *)syncSwitch.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    GCKCalendar *calendar = [calendars objectAtIndex:indexPath.section - 2];
    calendar.syncEnabled = [NSNumber numberWithBool:syncSwitch.on];
}

#pragma mark -

- (void)textFieldEditingChanged:(id)sender {
    if ([usernameField.text length] > 0 && [passwordField.text length] > 0) {
        updateLabel.textColor = [UIColor settingTextColor];
    } else {
        updateLabel.textColor = [UIColor grayColor];
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if ([usernameField.text length] > 0 && [passwordField.text length] > 0) {
        updateLabel.textColor = [UIColor settingTextColor];
    } else {
        updateLabel.textColor = [UIColor grayColor];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == usernameField) {
        [passwordField becomeFirstResponder];
    } else if (textField == passwordField) {
        if ([usernameField.text length] > 0 && [passwordField.text length] > 0) {
            updateLabel.textColor = [UIColor grayColor];
            [passwordField resignFirstResponder];
            [self updateCalendar];
        } else {
            [usernameField becomeFirstResponder];
        }
    }
    return YES;
}

@end
