//
//  GCKParticipant.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef enum {
    GCKParticipantTypeUnknown,
    GCKParticipantTypePerson,
    GCKParticipantTypeRoom,
    GCKParticipantTypeResource,
    GCKParticipantTypeGroup
} GCKParticipantType;

typedef enum {
    GCKParticipantRoleUnknown,
    GCKParticipantRoleRequired,
    GCKParticipantRoleOptional,
    GCKParticipantRoleChair,
    GCKParticipantRoleNonParticipant
} GCKParticipantRole;

typedef enum {
    GCKParticipantStatusUnknown,
    GCKParticipantStatusPending,
    GCKParticipantStatusAccepted,
    GCKParticipantStatusDeclined,
    GCKParticipantStatusTentative,
    GCKParticipantStatusDelegated,
    GCKParticipantStatusCompleted,
    GCKParticipantStatusInProcess
} GCKParticipantStatus;

@interface GCKParticipant :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * URL;
@property (nonatomic, retain) NSNumber * participantType;
@property (nonatomic, retain) NSNumber * participantRole;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * participantStatus;

@end



