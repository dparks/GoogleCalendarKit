//
//  GoogleTimeZoneUtilities.m
/* Copyright (c) 2008 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GoogleTimeZoneUtilities.h"

@interface GoogleTimeZoneUtilities (PrivateMethods)
- (NSString *)googleSafeTimeZoneNameWithOffset:(int)offsetSeconds
                                        prefix:(NSString *)prefixOrNil
                                          date:(NSDate *)dateOrNil;  

- (NSString *)canonicalTimeZoneNameForName:(NSString *)name;
- (NSDictionary *)timeZoneAliases;
- (NSString *)prefixUpToFirstSlashForString:(NSString *)input;
@end

static int TimeZoneSortFunction(NSString *str1, NSString *str2, void *context) {
    
    // We'll sort our constructed array of time zone names since otherwise
    // the array built from an NSSet is non-deterministic in order and harder
    // to unit test reliably
    
    // Prefer shorter zone names (a/b before a/b/c)
    NSArray *parts1 = [str1 componentsSeparatedByString:@"/"];
    NSArray *parts2 = [str2 componentsSeparatedByString:@"/"];
    
    unsigned int numParts1 = [parts1 count];
    unsigned int numParts2 = [parts2 count];
    
    if (numParts1 < numParts2) return NSOrderedAscending;
    if (numParts1 > numParts2) return NSOrderedDescending;
    
    // prefer non-Antarctica
    NSString *firstPart1 = [parts1 objectAtIndex:0];
    NSString *firstPart2 = [parts2 objectAtIndex:0];
    
    if ([firstPart1 isEqual:@"Antarctica"]) return NSOrderedDescending;
    if ([firstPart2 isEqual:@"Antarctica"]) return NSOrderedAscending;
    
    // alphabetical
    return [str1 caseInsensitiveCompare:str2];
}

static GoogleTimeZoneUtilities *sharedUtilities = nil;

@implementation GoogleTimeZoneUtilities

// TODO: not thread safe: initialize this before going multi-threaded.
+ (GoogleTimeZoneUtilities *)sharedUtilities {
    if (sharedUtilities == nil) {
        sharedUtilities = [[GoogleTimeZoneUtilities alloc] init];
    }
    return sharedUtilities;
}

// find a time zone name for the given offset seconds from GMT.  If a prefix
// is provided, search the full (canonical and non-canonical) names beginning
// with that prefix for a matching offset.  If no prefix is provided, 
// search only the canonical time zone names for a matching offset.
//
// prefixOrNil should be the prefix with a trailing slash (like "US/")
//
// returns a canonical name for a time zone with matching offset seconds,
// or nil if none found

- (NSString *)googleSafeTimeZoneNameWithOffset:(int)offsetSeconds
                                        prefix:(NSString *)prefixOrNil
                                          date:(NSDate *)dateOrNil {
    NSArray *zoneNameSearchList;
    
    // make a list of time zone names that we'll evaluate for matching
    // seconds offset
    if ([prefixOrNil length] == 0) {
        
        // we'll search all canonical zones, which are the dictionary values
        zoneNameSearchList = [[self timeZoneAliases] allValues];
        
    } else {
        // we'll search time zones, canonical or not (like US/Pacific), 
        // with the matching prefix
        //
        // using sets removes duplicates
        NSMutableSet *allZonesSet = [NSMutableSet set];
        [allZonesSet addObjectsFromArray:[[self timeZoneAliases] allKeys]];
        [allZonesSet addObjectsFromArray:[[self timeZoneAliases] allValues]];
        NSArray *allZoneNames = [allZonesSet allObjects];
        
        // we could cache the compiled predicate if profiles show a bottleneck here
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@",
                             prefixOrNil, nil];
        zoneNameSearchList = [allZoneNames filteredArrayUsingPredicate:pred];
    }
    
    // sort so we're searching a predictably-ordered list
    zoneNameSearchList = [zoneNameSearchList sortedArrayUsingFunction:TimeZoneSortFunction
                                                              context:nil];
    
    // default to offset from GMT for right now
    NSDate *date = dateOrNil ? dateOrNil : [NSDate date];
    
    // search the list of time zones, looking for one with an appropriate offset
    int idx;
    for (idx = 0; idx < [zoneNameSearchList count]; idx++) {
        
        NSString *testName = [zoneNameSearchList objectAtIndex:idx];
        NSString *canonicalTestName = [self canonicalTimeZoneNameForName:testName];
        NSTimeZone *testTimeZone = [NSTimeZone timeZoneWithName:canonicalTestName];
        
        if (testTimeZone 
            && [testTimeZone secondsFromGMTForDate:date] == offsetSeconds) {
            
            // this time zone works
            return canonicalTestName;
        }
    }
    return nil;
}

// converts the name of |timeZone| to a time zone name safe to send
// to Google Calendar, based on the time zone offset from GMT.
//
// Open question:
// Should we assume that |timeZone| has proper value of isDaylightSavingsTime?
// If we did, we could do a more reliable comparison to canonical time zones.
//
// |dateOrNil| may be nil to indicate "compare offsets from GMT as of right now"
//
- (NSString *)googleTimeZoneNameForTimeZone:(NSTimeZone *)timeZone
                                       date:(NSDate *)dateOrNil {
    
    NSString *originalName = [timeZone name];
    NSString *name = [self canonicalTimeZoneNameForName:originalName];
    
    // NSTimeZone defaults to zones with names beginning with GMT,
    // which Google calendar doesn't like
    if ([name hasPrefix:@"GMT"] || [name hasPrefix:@"Etc"]) {
        
        NSDate *date = dateOrNil ? dateOrNil : [NSDate date];
        
        int origSecondsFromGMT = [timeZone secondsFromGMTForDate:date];
        
        int localSecondsFromGMT = [[self localTimeZone] secondsFromGMTForDate:date];
        NSString *localZoneName = [[self localTimeZone] name];
        
        if (origSecondsFromGMT == localSecondsFromGMT) {
            
            // the target is in the local time zone
            name = [self canonicalTimeZoneNameForName:localZoneName];
            
        } else {
            // find a time zone with the desired GMT offset with the same first 
            // first component
            
            NSString *prefix = [self prefixUpToFirstSlashForString:localZoneName];
            name = [self googleSafeTimeZoneNameWithOffset:origSecondsFromGMT
                                                   prefix:prefix
                                                     date:date];
            if (!name) {
                // our local zone name was no help; search all time zones for
                // a possible match
                name = [self googleSafeTimeZoneNameWithOffset:origSecondsFromGMT
                                                       prefix:nil
                                                         date:date];
            }
            
            if (!name) {
                // there's no name for GMT-0100
                name = [timeZone name]; 
            }
        }
    }
    return name;
}

// returns the supplied |name| unless the alias list provides a better name
- (NSString *)canonicalTimeZoneNameForName:(NSString *)name {
    NSDictionary *aliasDict = [self timeZoneAliases];
    
    NSString *betterName = [aliasDict objectForKey:name];
    if (betterName) {
        name = betterName;
    } 
    return name;
}

// return the contents of the string up to including the first slash,
// or else return the whole string
- (NSString *)prefixUpToFirstSlashForString:(NSString *)input {
    
    NSArray *parts = [input componentsSeparatedByString:@"/"];
    
    if ([parts count] > 1) {
        
        // return the first part, including a slash
        return [[parts objectAtIndex:0] stringByAppendingString:@"/"];
    }
    return input;
}

#pragma mark -

- (NSTimeZone *)localTimeZone {
    
    if (localTimeZone_) {
        return localTimeZone_;
    }
    
    return [NSTimeZone localTimeZone];
}

- (void)setLocalTimeZone:(NSTimeZone *)tz {
    [localTimeZone_ autorelease];
    localTimeZone_ = [tz retain];
}

- (NSDictionary *)timeZoneAliases {
    
    if (!timeZoneAliases_) {
        
        // from //depot/google3/third_party/cldr/tools/java/org/unicode/cldr/icu/timezone_aliases.txt
        timeZoneAliases_ = [[NSDictionary alloc] initWithObjectsAndKeys:
                            // list of
                            // canonical (Google-safe) name value, non-canonical alias key
                            @"Australia/Darwin", @"ACT",
                            @"Australia/Sydney", @"AET",
                            @"America/Buenos_Aires", @"AGT",
                            @"Africa/Cairo", @"ART",
                            @"America/Anchorage", @"AST",
                            @"America/Adak", @"America/Atka",
                            @"America/Tijuana", @"America/Ensenada",
                            @"America/Indianapolis", @"America/Fort_Wayne",
                            @"America/Indianapolis", @"America/Indiana/Indianapolis",
                            @"America/Louisville", @"America/Kentucky/Louisville",
                            @"America/Indiana/Knox", @"America/Knox_IN",
                            @"America/Rio_Branco", @"America/Porto_Acre",
                            @"America/Cordoba", @"America/Rosario",
                            @"America/Denver", @"America/Shiprock",
                            @"America/St_Thomas", @"America/Virgin",
                            @"Antarctica/McMurdo", @"Antarctica/South_Pole",
                            @"Europe/Oslo", @"Arctic/Longyearbyen",
                            @"Asia/Ashgabat", @"Asia/Ashkhabad",
                            @"Asia/Chongqing", @"Asia/Chungking",
                            @"Asia/Dhaka", @"Asia/Dacca",
                            @"Europe/Istanbul", @"Asia/Istanbul",
                            @"Asia/Macau", @"Asia/Macao",
                            @"Asia/Jerusalem", @"Asia/Tel_Aviv",
                            @"Asia/Thimphu", @"Asia/Thimbu",
                            @"Asia/Makassar", @"Asia/Ujung_Pandang",
                            @"Asia/Ulaanbaatar", @"Asia/Ulan_Bator",
                            @"Australia/Sydney", @"Australia/ACT",
                            @"Australia/Sydney", @"Australia/Canberra",
                            @"Australia/Lord_Howe", @"Australia/LHI",
                            @"Australia/Sydney", @"Australia/NSW",
                            @"Australia/Darwin", @"Australia/North",
                            @"Australia/Brisbane", @"Australia/Queensland",
                            @"Australia/Adelaide", @"Australia/South",
                            @"Australia/Hobart", @"Australia/Tasmania",
                            @"Australia/Melbourne", @"Australia/Victoria",
                            @"Australia/Perth", @"Australia/West",
                            @"Australia/Broken_Hill", @"Australia/Yancowinna",
                            @"America/Sao_Paulo", @"BET",
                            @"Asia/Dhaka", @"BST",
                            @"America/Porto_Acre", @"Brazil/Acre",
                            @"America/Noronha", @"Brazil/DeNoronha",
                            @"America/Sao_Paulo", @"Brazil/East",
                            @"America/Manaus", @"Brazil/West",
                            @"Africa/Harare", @"CAT",
                            @"America/St_Johns", @"CNT",
                            @"America/Chicago", @"CST",
                            @"America/Chicago", @"CST6CDT",
                            @"Asia/Shanghai", @"CTT",
                            @"America/Halifax", @"Canada/Atlantic",
                            @"America/Winnipeg", @"Canada/Central",
                            @"America/Regina", @"Canada/East-Saskatchewan",
                            @"America/Toronto", @"Canada/Eastern",
                            @"America/Edmonton", @"Canada/Mountain",
                            @"America/St_Johns", @"Canada/Newfoundland",
                            @"America/Vancouver", @"Canada/Pacific",
                            @"America/Regina", @"Canada/Saskatchewan",
                            @"America/Whitehorse", @"Canada/Yukon",
                            @"America/Santiago", @"Chile/Continental",
                            @"Pacific/Easter", @"Chile/EasterIsland",
                            @"America/Havana", @"Cuba",
                            @"Africa/Addis_Ababa", @"EAT",
                            @"Europe/Paris", @"ECT",
                            @"America/Indianapolis", @"EST",
                            @"America/New_York", @"EST5EDT",
                            @"Africa/Cairo", @"Egypt",
                            @"Europe/Dublin", @"Eire",
                            @"Etc/GMT", @"Etc/GMT+0",
                            @"Etc/GMT", @"Etc/GMT-0",
                            @"Etc/GMT", @"Etc/GMT0",
                            @"Etc/GMT", @"Etc/Greenwich",
                            @"Etc/UTC", @"Etc/Universal",
                            @"Etc/UTC", @"Etc/Zulu",
                            @"Asia/Nicosia", @"Europe/Nicosia",
                            @"Europe/Chisinau", @"Europe/Tiraspol",
                            @"Europe/London", @"GB",
                            @"Europe/London", @"GB-Eire",
                            @"Etc/GMT", @"GMT",
                            @"Etc/GMT+0", @"GMT+0",
                            @"Etc/GMT-0", @"GMT-0",
                            @"Etc/GMT0", @"GMT0",
                            @"Etc/Greenwich", @"Greenwich",
                            @"Pacific/Honolulu", @"HST",
                            @"Asia/Hong_Kong", @"Hongkong",
                            @"America/Indianapolis", @"IET",
                            @"Asia/Calcutta", @"IST",
                            @"Atlantic/Reykjavik", @"Iceland",
                            @"Asia/Tehran", @"Iran",
                            @"Asia/Jerusalem", @"Israel",
                            @"Asia/Tokyo", @"JST",
                            @"America/Jamaica", @"Jamaica",
                            @"Asia/Tokyo", @"Japan",
                            @"Pacific/Kwajalein", @"Kwajalein",
                            @"Africa/Tripoli", @"Libya",
                            @"Pacific/Apia", @"MIT",
                            @"America/Phoenix", @"MST",
                            @"America/Denver", @"MST7MDT",
                            @"America/Tijuana", @"Mexico/BajaNorte",
                            @"America/Mazatlan", @"Mexico/BajaSur",
                            @"America/Mexico_City", @"Mexico/General",
                            @"Asia/Riyadh87", @"Mideast/Riyadh87",
                            @"Asia/Riyadh88", @"Mideast/Riyadh88",
                            @"Asia/Riyadh89", @"Mideast/Riyadh89",
                            @"Asia/Yerevan", @"NET",
                            @"Pacific/Auckland", @"NST",
                            @"Pacific/Auckland", @"NZ",
                            @"Pacific/Chatham", @"NZ-CHAT",
                            @"America/Denver", @"Navajo",
                            @"Asia/Karachi", @"PLT",
                            @"America/Phoenix", @"PNT",
                            @"Asia/Shanghai", @"PRC",
                            @"America/Puerto_Rico", @"PRT",
                            @"America/Los_Angeles", @"PST",
                            @"America/Los_Angeles", @"PST8PDT",
                            @"Pacific/Pago_Pago", @"Pacific/Samoa",
                            @"Europe/Warsaw", @"Poland",
                            @"Europe/Lisbon", @"Portugal",
                            @"Asia/Taipei", @"ROC",
                            @"Asia/Seoul", @"ROK",
                            @"Pacific/Guadalcanal", @"SST",
                            @"Asia/Singapore", @"Singapore",
                            @"America/Puerto_Rico", @"SystemV/AST4",
                            @"America/Halifax", @"SystemV/AST4ADT",
                            @"America/Regina", @"SystemV/CST6",
                            @"America/Chicago", @"SystemV/CST6CDT",
                            @"America/Indianapolis", @"SystemV/EST5",
                            @"America/New_York", @"SystemV/EST5EDT",
                            @"Pacific/Honolulu", @"SystemV/HST10",
                            @"America/Phoenix", @"SystemV/MST7",
                            @"America/Denver", @"SystemV/MST7MDT",
                            @"Pacific/Pitcairn", @"SystemV/PST8",
                            @"America/Los_Angeles", @"SystemV/PST8PDT",
                            @"Pacific/Gambier", @"SystemV/YST9",
                            @"America/Anchorage", @"SystemV/YST9YDT",
                            @"Europe/Istanbul", @"Turkey",
                            @"Etc/UCT", @"UCT",
                            @"America/Anchorage", @"US/Alaska",
                            @"America/Adak", @"US/Aleutian",
                            @"America/Phoenix", @"US/Arizona",
                            @"America/Chicago", @"US/Central",
                            @"America/Indianapolis", @"US/East-Indiana",
                            @"America/New_York", @"US/Eastern",
                            @"Pacific/Honolulu", @"US/Hawaii",
                            @"America/Indiana/Knox", @"US/Indiana-Starke",
                            @"America/Detroit", @"US/Michigan",
                            @"America/Denver", @"US/Mountain",
                            @"America/Los_Angeles", @"US/Pacific",
                            @"America/Los_Angeles", @"US/Pacific-New",
                            @"Pacific/Pago_Pago", @"US/Samoa",
                            @"Etc/UTC", @"UTC",
                            @"Etc/Universal", @"Universal",
                            @"Asia/Saigon", @"VST",
                            @"Europe/Moscow", @"W-SU",
                            @"Etc/Zulu", @"Zulu",
                            nil];
    }
    return timeZoneAliases_;
}

@end
