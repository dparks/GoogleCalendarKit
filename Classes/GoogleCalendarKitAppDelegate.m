//
//  GoogleCalendarKitAppDelegate.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GoogleCalendarKitAppDelegate.h"
#import "GCKDataSource.h"
#import "GCKSyncGroup.h"
#import "GCKSync.h"
#import "GCKEventStore.h"
#import "GCKSettingViewController.h"
#import "Kal.h"
#import "UIImage+Tint.h"

@implementation GoogleCalendarKitAppDelegate

- (void)dealloc {    
    [kal release];
    [dataSource release];
    [navController release];
    
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    
    [window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    kal = [[KalViewController alloc] init];
    
    kal.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Today" style:UIBarButtonItemStyleBordered target:self action:@selector(showAndSelectToday)] autorelease];
    kal.delegate = self;
    dataSource = [[GCKDataSource alloc] init];
    kal.dataSource = dataSource;
    
    navController = [[UINavigationController alloc] initWithRootViewController:kal];
    
    UIBarButtonItem *settingButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"settings_small.png"] imageTintedWithColor:[UIColor whiteColor]] style:UIBarButtonItemStyleBordered target:self action:@selector(showSettingView:)];
    kal.navigationItem.leftBarButtonItem = settingButton;
    [settingButton release];
    
    [window addSubview:navController.view];
    [window makeKeyAndVisible];
    
    [self performSelector:@selector(startSync) withObject:nil afterDelay:1.0];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}

#pragma mark -

- (void)showSettingView:(id)sender {    
    GCKSettingViewController *controller = [[GCKSettingViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [kal presentModalViewController:navigationController animated:YES];
    [controller release];
    [navigationController release];
}

- (void)startSync {
    LOG_CURRENT_METHOD;
    GCKSyncGroup *syncGroup = [GCKSyncGroup syncGroup];
    
    GCKEventStore *eventStore = [GCKEventStore defaultEventStore];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:@"username"];
    NSString *password = [defaults objectForKey:@"password"];
    
    NSArray *calendars = [eventStore allCalendars];
    for (GCKCalendar *calendar in calendars) {
        if (![calendar.syncEnabled boolValue]) {
            continue;
        }
        GCKSync *sync = [GCKSync syncWithUsername:username password:password];
        [syncGroup addSync:sync calendar:calendar];
    }
    
    [syncGroup start];
}

#pragma mark -

- (void)saveContext {
    NSError *error = nil;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

- (NSManagedObjectContext *)managedObjectContext {
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"GoogleCalendarKit" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"GoogleCalendarKit.sqlite"]];
    
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return persistentStoreCoordinator;
}

#pragma mark -

- (void)showAndSelectToday {
    [kal showAndSelectDate:[NSDate date]];
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LOG_CURRENT_METHOD;
}

#pragma mark -

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end
