//  GoogleTimeZoneUtilities.h
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
//

#import <Foundation/Foundation.h>

@interface GoogleTimeZoneUtilities : NSObject {
    NSDictionary* timeZoneAliases_;
    NSTimeZone* localTimeZone_; // for unit testing; otherwise nil
}

+ (GoogleTimeZoneUtilities *)sharedUtilities;

// for a given time zone and an optional date of interest, return
// a best-guess time zone name that Google's servers will like
- (NSString *)googleTimeZoneNameForTimeZone:(NSTimeZone *)timeZone
                                       date:(NSDate *)dateOrNil;

- (NSTimeZone *)localTimeZone;
- (void)setLocalTimeZone:(NSTimeZone *)tz; // set during testing only
@end
