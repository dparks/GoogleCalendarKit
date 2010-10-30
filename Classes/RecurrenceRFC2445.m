//  RecurrenceRFC2445.m
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
// More data on time zones at:
// http://www.twinsun.com/tz/tz-link.htm
//
#define RECURRENCE_RFC2445_DEFINE_GLOBALS 1
#import "RecurrenceRFC2445.h"
#import "GData.h"
#import "GoogleTimeZoneUtilities.h"
#import "LCCalendarDate.h"

static NSDictionary *gKeywordDict = nil;
static NSDictionary *gRecurrenceKeywordDict = nil;
static NSDictionary *gRecurrenceDayOfWeekDict = nil;
static NSDictionary *gRecurrenceUnitsDict = nil;
static NSDictionary *gRecurrenceDayOfWeekInverseDict = nil;
static NSCharacterSet *gEmptyCharacterSet = nil;
static NSCharacterSet *gEOLCharacterSet = nil;
static NSCharacterSet *gDateCharacterSet = nil;
static NSCharacterSet *gAllButColonCharacterSet = nil;
static NSCharacterSet *gExtendedAlphaNumericCharacterSet = nil;

@interface GDataDateTime(Additions)

- (NSString *)descriptionWithCalendarFormat:(NSString *)format;

@end

@implementation GDataDateTime(Additions)

- (NSString *)descriptionWithCalendarFormat:(NSString *)format {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [formatter setDateFormat:format];
    [formatter setTimeZone:[self timeZone]];
    return [formatter stringFromDate:[self date]];
}

@end

static BOOL IsAllNumeric(NSString *s) {
    int i;
    int length = [s length];
    for (i = 0;i < length; ++i) {
        unichar c = [s characterAtIndex:i];
        if ( ! ('0' <= c && c <= '9')) {
            return NO;
        }
    }
    return YES;
}

// We use the English text, unlocalized, because that is how the interface
// to Sync Services Manager is defined.
static NSString * const gDayOfWeek[] = {
    @"sunday",
    @"monday",
    @"tuesday",
    @"wednesday",
    @"thursday",
    @"friday",
    @"saturday"};
static NSString * const kDailyValue = @"daily";
static NSString * const kWeeklyValue = @"weekly";

// 
static NSString *RecurrenceStringFromDateZone(id arg, BOOL hasZone) {
    NSCAssert(arg, @"");
    GDataDateTime *date = nil;
    if ([arg respondsToSelector:@selector(hasTime)]) {
        date = arg;
    } else if ([arg respondsToSelector:@selector(length)]) {
        date = [GDataDateTime dateTimeWithRFC3339String:arg];
    } else {
        return @"";
    }
    
    NSString *val = nil;
    if ([date hasTime]) {
        
        NSTimeZone *zone = [date timeZone];
        if (0 == [zone secondsFromGMT] || [date isUniversalTime]) {
            // UTC
            val = [date descriptionWithCalendarFormat:@"yyyyMMdd'T'HHmmss'Z'"];
        } else {
            val = @"";
            if (zone && hasZone) {
                // NSTimeZone tends to emit time zone names like "GMT-700" which 
                // Google Calendar mis-parses as GMT.  We'll use a utility to
                // find a Google-safe time zone name.
                GoogleTimeZoneUtilities* tzUtils = [GoogleTimeZoneUtilities sharedUtilities];
                NSString *timeZoneName = [tzUtils googleTimeZoneNameForTimeZone:zone
                                                                           date:[date date]];
                
                val = [NSString stringWithFormat:@"TZID=%@:", timeZoneName];
            }
            val = [val stringByAppendingString:[date descriptionWithCalendarFormat:@"yyyyMMdd'T'HHmmss"]];
        }
    } else {
        val = [date descriptionWithCalendarFormat:@"yyyyMMdd"];
    }
    return val;
}

NSString *RecurrenceStringFromDate(id arg) {
    return RecurrenceStringFromDateZone(arg, YES);
}

NSString *RecurrenceStringNoZoneFromDate(id arg) {
    return RecurrenceStringFromDateZone(arg, NO);
}

// generate the prefix of the recurrence rule clause
static void RecurrenceRuleInit(NSMutableString *ioValue) {
    NSCAssert(ioValue, @"");
    if (0 == [ioValue length]) {
        [ioValue appendString:@"RRULE:"];
    } else {
        [ioValue appendString:@";"];
    }
}

// generate the FREQ=WEEKLY clause
static void RecurrenceToStringAppendNumber(NSDictionary* dictS, NSString *key, NSString *keyWord, NSMutableString *ioValue) {
    NSNumber *valueN = [dictS objectForKey:key];
    if (valueN) {
        RecurrenceRuleInit(ioValue);
        [ioValue appendString:[NSString stringWithFormat:@"%@=%@", keyWord, valueN]];    
    }
}

static void RecurrenceToStringAppendUntilDate(NSDictionary *dictS, NSString *key, NSString *keyWord, NSMutableString *ioValue) {
    id date = [dictS objectForKey:key];
    if ([date isKindOfClass:[NSDate class]] && ![date isKindOfClass:[GDataDateTime class]]) {
        date = [GDataDateTime dateTimeWithDate:date timeZone:[[NSCalendar currentCalendar] timeZone]];
    }
    if (date) {
        RecurrenceRuleInit(ioValue);
        [ioValue appendString:[NSString stringWithFormat:@"%@=%@", keyWord, RecurrenceStringFromDate(date)]];    
    }
}

// generate the COUNT=3 clause
static void RecurrenceToStringAppendUppercaseString(NSDictionary* dictS, NSString *key, NSString *keyWord, NSMutableString *ioValue) {
    NSString *valueS = [dictS objectForKey:key];
    if (valueS) {
        RecurrenceRuleInit(ioValue);
        [ioValue appendString:[NSString stringWithFormat:@"%@=%@",keyWord, [valueS uppercaseString]]];    
    }
}

// generate the WKST=MO clause
static void RecurrenceToStringAppendWeekStartDay(NSDictionary* dictS, NSString *key, NSString *keyWord, NSMutableString *ioValue) {
    NSString *valueS = [dictS objectForKey:key];
    if (valueS) {
        valueS = [gRecurrenceDayOfWeekInverseDict objectForKey:valueS];
        if (valueS) {
            RecurrenceRuleInit(ioValue);
            [ioValue appendString:[NSString stringWithFormat:@"%@=%@",keyWord, valueS]];    
        }
    }
}

// generate the COUNT=3 clause
static void RecurrenceToStringAppendArrayOfNumber(NSDictionary* dictS, NSString *key, NSString *keyWord, NSMutableString *ioValue) {
    NSArray *valueA = [dictS objectForKey:key];
    if (0 < [valueA count]) {
        RecurrenceRuleInit(ioValue);
        NSEnumerator *enumerator = [valueA objectEnumerator];
        NSNumber *n = [enumerator nextObject];
        [ioValue appendString:[NSString stringWithFormat:@"%@=%@", keyWord, n]];
        while (nil != (n = [enumerator nextObject])) {
            [ioValue appendString:[NSString stringWithFormat:@",%@", n]];
        }
    }
}

// generate the BYDAY=MO,WE,FR clause
// generate the BYDAY=-2MO clause
static void RecurrenceToStringAppendArrayOf2CharacterDayAbreviations(NSDictionary* dictS, NSString *freqKey, NSString *dayKey, NSString *keyWord, NSMutableString *ioValue) {
    NSArray *valueA = [dictS objectForKey:dayKey];
    NSArray *frequencyA = [dictS objectForKey:freqKey];
    if (0 < [valueA count]) {
        NSMutableString *clause = [NSMutableString string];
        NSEnumerator *valueEnumerator = [valueA objectEnumerator];
        NSEnumerator *frequencyEnumerator = [frequencyA objectEnumerator];
        NSString *valueS;
        while (nil != (valueS = [valueEnumerator nextObject])) {
            id frequencyN = [frequencyEnumerator nextObject]; // usually a number.
            id frequency = frequencyN ? frequencyN : (id) @"";
            valueS = [gRecurrenceDayOfWeekInverseDict objectForKey:valueS];
            if (valueS) {
                if (0 == [clause length]) {
                    [clause appendString:[NSString stringWithFormat:@"%@=%@%@", keyWord, frequency, valueS]];
                } else {
                    [clause appendString:[NSString stringWithFormat:@",%@%@", frequency, valueS]];
                }
            }
        }
        if (0 < [clause length]) {
            RecurrenceRuleInit(ioValue);
            [ioValue appendString:clause];
        }
    }
}

@interface RecurrenceRFC2445(PrivateMethods)
- (NSMutableString *)nextContentLine;
- (NSString *)parseToken:(NSScanner *)scannerOfLine;
- (SEL)parseClause:(NSScanner *)scannerOfLine;
- (void)ruleTimeKey:(NSString *)timeKey forScanner:(NSScanner *)scannerOfLine;
- (void)ruleBEGIN:(NSScanner *)scannerOfLine;
- (void)ruleEND:(NSScanner *)scannerOfLine;
- (void)ruleEXDATE:(NSScanner *)scannerOfLine;
- (void)ruleEXRULE:(NSScanner *)scannerOfLine;
- (void)ruleDTSTART:(NSScanner *)scannerOfLine;
- (void)ruleDTEND:(NSScanner *)scannerOfLine;
- (void)ruleDURATION:(NSScanner *)scannerOfLine;
- (void)ruleRRULE:(NSScanner *)scannerOfLine;
- (void)ruleTZID:(NSScanner *)scannerOfLine;
- (void)recurCOUNT:(NSScanner *)scannerOfLine;
- (void)recurBYSECOND:(NSScanner *)scannerOfLine;
- (void)recurBYMINUTE:(NSScanner *)scannerOfLine;
- (void)recurBYHOUR:(NSScanner *)scannerOfLine;
- (void)recurBYWEEKNO:(NSScanner *)scannerOfLine;
- (void)recurBYMONTHDAY:(NSScanner *)scannerOfLine;
- (void)recurBYDAY:(NSScanner *)scannerOfLine;
- (void)recurBYMONTH:(NSScanner *)scannerOfLine;
- (void)recurBYSETPOS:(NSScanner *)scannerOfLine;
- (void)recurBYWEEK:(NSScanner *)scannerOfLine;
- (void)recurBYYEAR:(NSScanner *)scannerOfLine;
- (void)recurFREQ:(NSScanner *)scannerOfLine;
- (void)recurINTERVAL:(NSScanner *)scannerOfLine;
- (void)ruleRDATE:(NSScanner *)scannerOfLine;
- (void)recurUNTIL:(NSScanner *)scannerOfLine;
- (void)recurWKST:(NSScanner *)scannerOfLine;
- (void)setTimeZone:(NSTimeZone *)timeZone;
- (NSTimeZone *)timeZone;
- (NSDictionary *)prepareForGenerateString:(NSDictionary *)dictS;
- (void)prepareForGenerateDictionary:(NSMutableDictionary *)dict;
@end
@implementation RecurrenceRFC2445

// We use the English text, unlocalized, because that is how the interfaces
// to Sync Services Manager and RFC2445 are defined.
+ (void)initialize {
    if (self == [RecurrenceRFC2445 class] ) {
        // only create the charactersets once
        gEmptyCharacterSet =
        [[NSCharacterSet characterSetWithCharactersInString:@""] retain];
        gEOLCharacterSet =
        [[NSCharacterSet characterSetWithCharactersInString:@"\r\n"] retain];
        gDateCharacterSet =
        [[NSCharacterSet characterSetWithCharactersInString:@"0123456789+-TZ"] retain];
        gAllButColonCharacterSet =
        [[[NSCharacterSet characterSetWithCharactersInString:@":"] invertedSet] retain];
        NSMutableCharacterSet *extendedAlphaNumeric =
        [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [extendedAlphaNumeric addCharactersInString:@"-"];
        gExtendedAlphaNumericCharacterSet = extendedAlphaNumeric;
        // major verbs of a RFC445 recurence rule
        gKeywordDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                        [NSValue valueWithPointer:@selector(ruleBEGIN:)], @"BEGIN",
                        [NSValue valueWithPointer:@selector(ruleEND:)], @"END",
                        [NSValue valueWithPointer:@selector(ruleEXDATE:)], @"EXDATE",
                        [NSValue valueWithPointer:@selector(ruleEXRULE:)], @"EXRULE",
                        [NSValue valueWithPointer:@selector(ruleDTSTART:)], @"DTSTART",
                        [NSValue valueWithPointer:@selector(ruleDTEND:)], @"DTEND",
                        [NSValue valueWithPointer:@selector(ruleDURATION:)], @"DURATION",
                        [NSValue valueWithPointer:@selector(ruleRDATE:)], @"RDATE",
                        [NSValue valueWithPointer:@selector(ruleRRULE:)], @"RRULE",
                        [NSValue valueWithPointer:@selector(ruleTZID:)], @"TZID",
                        nil];
        // verbs of the RRULE line of a RFC445 recurrence rule
        gRecurrenceKeywordDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [NSValue valueWithPointer:@selector(recurBYSECOND:)], @"BYSECOND",
                                  [NSValue valueWithPointer:@selector(recurBYMINUTE:)], @"BYMINUTE",
                                  [NSValue valueWithPointer:@selector(recurBYHOUR:)], @"BYHOUR",
                                  [NSValue valueWithPointer:@selector(recurBYDAY:)], @"BYDAY",
                                  [NSValue valueWithPointer:@selector(recurBYMONTH:)], @"BYMONTH",
                                  [NSValue valueWithPointer:@selector(recurBYMONTHDAY:)], @"BYMONTHDAY",
                                  [NSValue valueWithPointer:@selector(recurBYSETPOS:)], @"BYSETPOS",
                                  [NSValue valueWithPointer:@selector(recurBYWEEK:)], @"BYWEEK",
                                  [NSValue valueWithPointer:@selector(recurBYWEEKNO:)], @"BYWEEKNO",
                                  [NSValue valueWithPointer:@selector(recurBYYEAR:)], @"BYYEARDAY",
                                  [NSValue valueWithPointer:@selector(recurCOUNT:)], @"COUNT",
                                  [NSValue valueWithPointer:@selector(recurFREQ:)], @"FREQ",
                                  [NSValue valueWithPointer:@selector(recurINTERVAL:)], @"INTERVAL",
                                  [NSValue valueWithPointer:@selector(recurUNTIL:)], @"UNTIL",
                                  [NSValue valueWithPointer:@selector(recurWKST:)], @"WKST",
                                  nil];
        gRecurrenceDayOfWeekDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    gDayOfWeek[0], @"SU",
                                    gDayOfWeek[1], @"MO",
                                    gDayOfWeek[2], @"TU",
                                    gDayOfWeek[3], @"WE",
                                    gDayOfWeek[4], @"TH",
                                    gDayOfWeek[5], @"FR",
                                    gDayOfWeek[6], @"SA",
                                    nil];
        gRecurrenceDayOfWeekInverseDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           @"SU", gDayOfWeek[0],
                                           @"MO", gDayOfWeek[1],
                                           @"TU", gDayOfWeek[2],
                                           @"WE", gDayOfWeek[3],
                                           @"TH", gDayOfWeek[4],
                                           @"FR", gDayOfWeek[5],
                                           @"SA", gDayOfWeek[6],
                                           nil];
        gRecurrenceUnitsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                @"daily", @"DAILY",
                                @"weekly", @"WEEKLY",
                                @"monthly", @"MONTHLY",
                                @"yearly", @"YEARLY",
                                nil];
        // TODO: "SECONDLY" / "MINUTELY" / "HOURLY"
    }
}

+ (RecurrenceRFC2445 *)recurrence {
    return [[[RecurrenceRFC2445 alloc] init] autorelease];
}

- (id)init {
    if (nil != (self = [super init])) {
    }
    return self;
}

- (void)dealloc {
    [srcScanner_ release];
    [val_ release];
    [timeZone_ release];
    [super dealloc];
}

// given a legal RFC2445 string representing a recurrence, produce a
// dictionary that iCal expects.
// input is utf-8 text, structured as a sequence of command lines.
// commandlines are  {verb}:arguments. typically: BEGIN:VTIMEZONE
// we pick off the first token, look it up in a dict to get the selector
// of a handler method and call that method to consume the rest of the line.
// (BEGIN can consume multiple lines.)
// If we don't recognize a line we silently skip it.
- (NSMutableDictionary *)recurrenceDictionaryFromString:(NSString *)recurrenceS {
    NSAssert(recurrenceS, @"");
    [srcScanner_ autorelease];
    srcScanner_ = [[NSScanner alloc] initWithString:recurrenceS];
    // set the skipped char to the empty set so whitespace isn't skipped (the default)
    [srcScanner_ setCharactersToBeSkipped:gEmptyCharacterSet];
    NSMutableString *contentLine;
    while (nil != (contentLine = [self nextContentLine])) {
        NSScanner *scannerWithLine = [NSScanner scannerWithString:contentLine];
        SEL clauseVerb = [self parseClause:scannerWithLine];
        if (clauseVerb) {
            [self performSelector:clauseVerb withObject:scannerWithLine];
        } else {
            NSLog(@"recurrenceDictionaryFromString: couldn't parse: \"%@\"", recurrenceS);
            break;
        }
    }
    [self prepareForGenerateDictionary:val_];
    return [[val_ retain] autorelease];
}

- (NSString *)recurrenceStringRuleFromDictionary:(NSDictionary *)dictS {
    dictS = [self prepareForGenerateString:dictS];
    NSMutableString *val = [NSMutableString string];
    
    RecurrenceToStringAppendUppercaseString(dictS, kRecurrenceFrequencyKey, @"FREQ", val);
    RecurrenceToStringAppendNumber(dictS, kRecurrenceIntervalKey, @"INTERVAL", val);
    RecurrenceToStringAppendNumber(dictS, kRecurrenceCountKey, @"COUNT", val);
    RecurrenceToStringAppendArrayOf2CharacterDayAbreviations(dictS, kRecurrenceByDayFreq, kRecurrenceByDayDays, @"BYDAY", val);
    RecurrenceToStringAppendArrayOfNumber(dictS, kRecurrenceByMonth, @"BYMONTH", val);
    RecurrenceToStringAppendArrayOfNumber(dictS, kRecurrenceByMonthDay, @"BYMONTHDAY", val);
    RecurrenceToStringAppendArrayOfNumber(dictS, kRecurrenceBySetPos, @"BYSETPOS", val);
    RecurrenceToStringAppendArrayOfNumber(dictS, kRecurrenceByWeekNumber, @"BYWEEKNO", val);
    RecurrenceToStringAppendArrayOfNumber(dictS, kRecurrenceByYearDay, @"BYYEARDAY", val);
    RecurrenceToStringAppendUntilDate(dictS, kRecurrenceUntilKey, @"UNTIL", val);
    RecurrenceToStringAppendWeekStartDay(dictS, kRecurrenceWeekStartDayKey, @"WKST", val);
    
    if (0 < [val length]) {
        [val appendString:@"\r\n"];
    }
    
    return val;
}

// if date is a TZID=XXX:20060731T140000 string, generate DTSTART;TZID=XXX:20060731T140000
// if date is a 20060731T140000Z string generate DTSTART;VALUE=DATE:20060731T140000Z
- (NSString *)recurrenceString:(NSString *)verb forDate:(GDataDateTime *)date {
    NSString *dateString = RecurrenceStringFromDate(date);
    NSString *val = nil;
    if ([dateString hasPrefix:@"T"]) {
        val = [NSString stringWithFormat:@"%@%@\r\n", verb, dateString];
    } else {
        val = [NSString stringWithFormat:@"%@VALUE=DATE:%@\r\n", verb, dateString];
    }
    return val;
}

- (GDataDateTime *)asGDataDateTime:(id)date
{
    return date;
}

// produce a RFC2445 string representing a recurrence given a dictionary form of a recurrence.
- (NSString *)recurrenceStringFromDictionary:(NSDictionary *)dictS {
    NSMutableString *val = [NSMutableString string];
    GDataDateTime *startDate = [self asGDataDateTime:[dictS objectForKey:kStartDateKey]];
    if (nil != startDate) {
        [val appendString:[self recurrenceString:@"DTSTART;" forDate:startDate]];
    }
    GDataDateTime *endDate = [self asGDataDateTime:[dictS objectForKey:kEndDateKey]];
    if (nil != endDate) {
        [val appendString:[self recurrenceString:@"DTEND;" forDate:endDate]];
    }
    NSNumber *valueN = [dictS objectForKey:kRecurrenceDurationKey];
    if (valueN) {
        int duration = [valueN intValue];
        [val appendString:[NSString stringWithFormat:@"DURATION:PT%dS\r\n", duration]];    
    }
    [val appendString:[self recurrenceStringRuleFromDictionary:dictS]];
    NSArray *exceptionArray = [dictS objectForKey:kExceptionDatesKey];
    int exceptionCount = [exceptionArray count];
    if (0 < exceptionCount) {
        GDataDateTime *firstExceptionDate = [self asGDataDateTime:[exceptionArray objectAtIndex:0]];
        NSString *firstDateString = RecurrenceStringNoZoneFromDate(firstExceptionDate);
        [val appendString:[NSString stringWithFormat:@"EXDATE;VALUE=DATE:%@", firstDateString]];
        int i;
        for(i = 1;i < exceptionCount; ++i){
            GDataDateTime *exceptionDate = [self asGDataDateTime:[exceptionArray objectAtIndex:i]];
            NSString *dateString = RecurrenceStringNoZoneFromDate(exceptionDate);
            [val appendString:[NSString stringWithFormat:@",%@", dateString]];
        }
        [val appendString:@"\r\n"];
    }
    return val;
}

- (NSString *)recurrenceStringFromDictionary:(NSDictionary *)dictS 
                                   startDate:(GDataDateTime *)startDate 
                                     endDate:(GDataDateTime *)endDate
                              exceptionDates:(NSArray *)exceptions {
    
    if (nil == startDate && nil == endDate) {
        return [self recurrenceStringFromDictionary:dictS];
    }
    NSMutableDictionary *dict = [[dictS mutableCopy] autorelease];
    if (startDate) {
        [dict setObject:startDate forKey:kStartDateKey];
    }
    if (endDate) {
        [dict setObject:endDate forKey:kEndDateKey];
    }
    if (exceptions) {
        [dict setObject:exceptions forKey:kExceptionDatesKey];
    }
    return [self recurrenceStringFromDictionary:dict];
}

// spec says if line ends with a line separator sequence, followed by whitespace,
// then text following the white space, then remove the return,whitepace, and
// treat the resulat as one long line. There may be many continuation lines.
- (NSMutableString *)nextContentLine {
    NSMutableString *line = nil;
    NSString *linePart = nil;
    BOOL hasMoreContinuation = YES;
    while (hasMoreContinuation) {
        if ([srcScanner_ scanUpToCharactersFromSet:gEOLCharacterSet
                                        intoString:&linePart]) {
            if (nil == line) {
                line = [[linePart mutableCopy] autorelease];
            } else {
                [line appendString:linePart];
            }
            NSString *eol = nil;
            NSString *whiteSpace = nil;
            if ([srcScanner_ scanCharactersFromSet:gEOLCharacterSet
                                        intoString:&eol]) {
                if ([srcScanner_ scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]
                                            intoString:&whiteSpace]) {
                    continue; // we've seen a continuation line.
                }
            }
        }
        hasMoreContinuation = NO;
    }
    return line;
}

- (NSString *)parseToken:(NSScanner *)scanner withIdentifierSet:(NSCharacterSet *)identifierSet {
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
    NSString *token = nil;
    if ( ! [scanner isAtEnd]) {
        NSString *line = [scanner string];
        unichar c = [line characterAtIndex:[scanner scanLocation]];
        unichar c2;
        if (('X' == c || 'x' == c) && [scanner scanLocation] + 1 < [line length] &&
            '-' == [line characterAtIndex:1+[scanner scanLocation]]) {
            // example: X-LOCATION-ID
            [scanner scanCharactersFromSet:gExtendedAlphaNumericCharacterSet
                                intoString:&token];
        }else if (('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z')) {
            [scanner scanCharactersFromSet:identifierSet intoString:&token];
        } else if ('0' <= c && c <= '9') {
            [scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&token];
        } else if ('+' == c && [scanner scanLocation] + 1 < [line length] &&
                   '0' <= (c2 = [line characterAtIndex:1+[scanner scanLocation]]) && c2 <= '9') {
            [scanner setScanLocation:[scanner scanLocation]+1];
            [scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&token];
        } else if ('-' == c && [scanner scanLocation] + 1 < [line length] &&
                   '0' <= (c2 = [line characterAtIndex:1+[scanner scanLocation]]) && c2 <= '9') {
            NSString *tail = nil;
            [scanner setScanLocation:[scanner scanLocation]+1];
            [scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&tail];
            token = [NSString stringWithFormat:@"-%@", tail];
        } else {
            token = [NSString stringWithCharacters:&c length:1];
            [scanner setScanLocation:[scanner scanLocation]+1];
        }
    }
    return token;
}

// input is a scanner wrapping a line, (continuation lines have been processed.)
// output is the next token, and scanner is advanced past the token. nil return at end.
// a token is punctuation character, a number, or an alphanumeric string.
// if the string starts with 'x-', then '-' is allowed in the alphanumeric token.
//
// The RFC2445 spec uses only 7-bit ASCII, so we can get away with literal C
// character constants here. Non-ASCII will be returned as a series of
// single-character tokens.

- (NSString *)parseToken:(NSScanner *)scanner {
    return [self parseToken:scanner withIdentifierSet:[NSCharacterSet alphanumericCharacterSet]];
}

- (NSString *)parseAlphabeticToken:(NSScanner *)scanner {
    return [self parseToken:scanner withIdentifierSet:[NSCharacterSet letterCharacterSet]];
}

// given a scanner for a line of the form:
// VERB:ARGUMENTS
//, looks up VERB in symbol table, calls handler func
// with scanner advanced to start of arguments.
- (SEL)parseClause:(NSScanner *)scannerOfLine {
    NSString *token = [self parseToken:scannerOfLine];
    if (nil == token) {
        NSLog(@"RecurrenceRFC2445 parseClause: Couldn't parse: \"%@\"", [scannerOfLine string]);
        return 0;
    }
    NSString *separator = [self parseToken:scannerOfLine];
    if (separator) {
    }
    NSValue *val = [gKeywordDict objectForKey:token];
    if (val) {
        return [val pointerValue];
    }
    return 0;
}

- (void)setOutputObject:(id)value forKey:(NSString *)key {
    if (nil == val_) {
        val_ = [[NSMutableDictionary alloc] init];
    }
    [val_ setObject:value forKey:key];
}

// advances the parser to the next clause
- (void)skipPastSemicolon:(NSScanner *)scannerOfLine {
    NSString *token = nil;
    while (nil != (token = [self parseToken:scannerOfLine])) {
        if ([@";" isEqual:token]) {
            break;
        }
    }
}

// returns nil if inS doesn't represent a valid integer. We disallow
// INT_MIN, INT_MAX.
- (NSNumber *)intNumberFromString:(NSString *)inS {
    NSAssert(inS, @"");
    NSScanner *scanner = [NSScanner scannerWithString:inS];
    NSNumber *number = nil;
    int n;
    if ([scanner scanInt:&n] && INT_MAX != n && INT_MIN != n) {
        number = [NSNumber numberWithInt:n];
    }
    return number;
}

// for clauses of the form: =44; return the NSArray of NSNumbers
// advances scanner past closest trailing ';' or end of line.
- (NSNumber *)parseIntegerClause:(NSScanner *)scannerOfLine {
    NSString *intParam = [self parseToken:scannerOfLine];
    NSNumber *intNumber = nil;
    if (intParam && nil != (intNumber = [self intNumberFromString:intParam])) {
        [self skipPastSemicolon:scannerOfLine];
    } else if ( ! [@";" isEqual:intParam]) {
        [self skipPastSemicolon:scannerOfLine];
    }
    return intNumber;
}

// parses date in yyyymmddThhmmssTZ form, example: 19960415T133000Z
// Caution! SyncServices works on NSCalendarDates, but this program
// works on GDataDateTime time stamps as strings, since it uses
// the AppKit NSDictionary serialization.
- (id)parseDate:(NSScanner *)scannerOfLine {
    NSDate *dateVal = nil;
    NSString *dateS = nil;
    id dateResult = nil;
    if ([scannerOfLine scanCharactersFromSet:gDateCharacterSet
                                  intoString:&dateS]) {
        BOOL hasTime = YES;
        BOOL hasTimeZone = YES;
        dateVal = [LCCalendarDate dateWithString:dateS calendarFormat:@"yyyyMMdd'T'HHmmssZZZ"];
        if (nil == dateVal) {
            hasTimeZone = NO;
            dateVal = [LCCalendarDate dateWithString:dateS calendarFormat:@"yyyyMMdd'T'HHmmss"];
        }
        if (nil == dateVal) {
            hasTime = NO;
            dateVal = [LCCalendarDate dateWithString:dateS calendarFormat:@"yyyyMMdd"];
        }
        if (dateVal) {
            GDataDateTime *dateRFC3339 = [GDataDateTime dateTimeWithDate:dateVal timeZone:[[NSCalendar currentCalendar] timeZone]];
            [dateRFC3339 setHasTime:hasTime];
            if (hasTime && ([dateS hasSuffix:@"Z"] || [dateS hasSuffix:@"z"])) {
                [dateRFC3339 setTimeZone:[NSTimeZone timeZoneWithName:@"Z"]];
            } else if (hasTime && ! hasTimeZone && [self timeZone]) {
                [dateRFC3339 setTimeZone:[self timeZone]];
            } else if (!hasTime) {
                [dateRFC3339 setIsUniversalTime:YES];
                [dateRFC3339 setOffsetSeconds:0];
            }
            dateResult = dateRFC3339;
        }
    }
    return dateResult;
}

// for clauses of the form: =-1,2,-3,3; return the NSArray of NSNumbers
// disalllow 0.
// advances scanner past closest trailing ';' or end of line.
- (NSArray *)parseIntegerArrayClause:(NSScanner *)scannerOfLine low:(int)low high:(int)high {
    NSString *token;
    NSMutableArray *numberList = nil;
    while (nil != (token = [self parseToken:scannerOfLine]) && ! [@";" isEqual:token]) {
        NSNumber *intNumber;
        int n;
        if (nil != (intNumber = [self intNumberFromString:token]) && 
            0 != (n = [intNumber intValue]) &&
            low <= n && n <= high) {
            
            if (numberList) {
                [numberList addObject:intNumber];
            } else { 
                numberList = [NSMutableArray arrayWithObject:intNumber];
            } 
            token = [self parseToken:scannerOfLine];
            if ( ! [@"," isEqual:token]) {  // expect comma separation.
                break;
            }
        } else {
            break;
        }
    }
    if ( ! [@";" isEqual:token]) {
        [self skipPastSemicolon:scannerOfLine];
    }
    return numberList;
}

// typically: BEGIN:VTIMEZONE   so, just skip past matching end line.
- (void)ruleBEGIN:(NSScanner *)scannerOfLine {
    NSString *token = [self parseToken:scannerOfLine];
    if ([@"VTIMEZONE" isEqual:token]) {
        NSMutableString *contentLine;
        while (nil != (contentLine = [self nextContentLine])) {
            NSScanner *scannerOfInnerLine = [NSScanner scannerWithString:contentLine];
            NSString *token = [self parseToken:scannerOfInnerLine];
            if ([@"END" isEqual:token]) {
                [self parseToken:scannerOfInnerLine];
                token = [self parseToken:scannerOfInnerLine];
                if ([@"VTIMEZONE" isEqual:token]) {
                    break;
                }
            }
        }
    }
}

// the BEGIN parsing rule skips to the matching end, so there's nothing
// we need do here.
- (void)ruleEND:(NSScanner *)scannerOfLine {
}

// Defines a list of date/time exceptions to the recurrence rule.
// Note: Google sends us multiple EXDATE lines.
// EXDATE:19960402T010000Z,19960403T010000Z,19960404T010000Z
// EXDATE;VALUE=DATE-TIME;TZID=America/Los_Angeles:20070214T150000
- (void)ruleEXDATE:(NSScanner *)scannerOfLine {
    // TODO: this line often begins a time zone definition, that we are discarding.
    NSString *token;
    NSMutableArray *dates = [val_ objectForKey:kExceptionDatesKey];
    while (nil != (token = [self parseToken:scannerOfLine])) {
        NSValue *val = [gKeywordDict objectForKey:token];
        if (val) {
            [self performSelector:[val pointerValue] withObject:scannerOfLine];
        }
        id date = [self parseDate:scannerOfLine];
        if (date) {
            if (dates) {
                [dates addObject:date];
            } else {
                dates = [NSMutableArray arrayWithObject:date];
            }
        }
    }
    if (dates) {
        [self setOutputObject:dates forKey:kExceptionDatesKey];
    }
}

// EXRULE:FREQ=WEEKLY;COUNT=4;INTERVAL=2;BYDAY=TU,TH
// EXRULE:FREQ=DAILY;COUNT=10
// EXRULE:FREQ=YEARLY;COUNT=8;BYMONTH=6,7
- (void)ruleEXRULE:(NSScanner *)scannerOfLine {
    NSString *token;
    while (nil != (token = [self parseToken:scannerOfLine])) {
        // TODO: Finish this up.
    }
}

// typically: DTSTART;TZID=US-Eastern:19970105T083000
// or: DTEND:19970105T083000
// in the second case, where the TZ is missing, we'll grab the 8-character 
// 19970105 in place of the color, so we'll need to back up the scanner.
// if we do back up, make sure we only do it once in a row, so we won't loop.
- (void)ruleTimeKey:(NSString *)timeKey forScanner:(NSScanner *)scannerOfLine {
    NSString *token;
    BOOL hasBackedUp = NO;
    while (nil != (token = [self parseToken:scannerOfLine])) {
        NSValue *val = [gKeywordDict objectForKey:token];
        if (val) {
            [self performSelector:[val pointerValue] withObject:scannerOfLine];
            hasBackedUp = NO;
        } else if ( ( ! hasBackedUp) && 8 == [token length] && IsAllNumeric(token)) {
            [scannerOfLine setScanLocation:[scannerOfLine scanLocation] - [token length]];
            hasBackedUp = YES;
        }
        id date = [self parseDate:scannerOfLine];
        if (date) {
            [self setOutputObject:date forKey:timeKey];
            break;
        }
    }
}

// typically: DTSTART;TZID=US-Eastern:19970105T083000
// TODO: if this line has a time zone definition, we discard it. We SHOULD honor it.
- (void)ruleDTSTART:(NSScanner *)scannerOfLine {
    [self ruleTimeKey:kStartDateKey forScanner:scannerOfLine];
}

// typically: DTEND;TZID=US-Eastern:19970105T083000
// TODO: this line often begins a time zone definition, that we are discarding.
- (void)ruleDTEND:(NSScanner *)scannerOfLine {
    [self ruleTimeKey:kEndDateKey forScanner:scannerOfLine];
}

/*
 bnf grammar:
 durvalue  := (["+"] | "-") "P" (durdate | durtime | durweek)
 
 durdate   := durday [durtime]
 durtime   := "T" (durhour | durminute | dursecond)
 durweek   := DIGIT+ "W"
 durhour   := DIGIT+ "H" [durminute]
 durminute := DIGIT+ "M" [dursecond]
 dursecond := DIGIT+ "S"
 durday    := DIGIT+ "D"
 example:
 DURATION:PT3600S
 */
- (void)ruleDURATION:(NSScanner *)scannerOfLine {
    BOOL isNegative = NO;
    [scannerOfLine scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
    NSString *line = [scannerOfLine string];
    if ([scannerOfLine scanLocation] + 2 < [line length]) {
        unichar c = [line characterAtIndex:[scannerOfLine scanLocation]];
        if ('-' == c || '+' == c) {
            [scannerOfLine setScanLocation:[scannerOfLine scanLocation]+1];
            if ('-' == c) {
                isNegative = YES;
            }
        }
        c = [line characterAtIndex:[scannerOfLine scanLocation]];
        if ('p' == c || 'P' == c) {
            [scannerOfLine setScanLocation:[scannerOfLine scanLocation]+1];
        }
    }
    NSString *num;
    NSString *units;
    int duration = 0;
    int n;
    while (nil != (num = [self parseAlphabeticToken:scannerOfLine]) && 
           nil != (units = [self parseAlphabeticToken:scannerOfLine])) {
        if ([num isEqual:@"T"] || [num isEqual:@"t"]) {
            num = units;
            units = [self parseToken:scannerOfLine];
        }
        
        n = [num intValue];
        if (0 != n) {
            if ([units isEqual:@"DT"] || [units isEqual:@"dt"]) {
                duration += (n * kSecondsInDay);
            } else if ([units isEqual:@"W"] || [units isEqual:@"w"]) {
                duration += (n * kSecondsInWeek);
            } else if ([units isEqual:@"H"] || [units isEqual:@"h"]) {
                duration += (n * kSecondsInHour);
            } else if ([units isEqual:@"M"] || [units isEqual:@"m"]) {
                duration += (n * kSecondsInMinute);
            } else if ([units isEqual:@"S"] || [units isEqual:@"s"]) {
                duration += n;
            }
        }
    }
    if (0 != duration) {
        [val_ setObject:[NSNumber numberWithInt:duration] forKey:kRecurrenceDurationKey];
    }
}

// TZID=America/Los_Angeles:
- (void)ruleTZID:(NSScanner *)scannerOfLine {
    NSString *separator = [self parseToken:scannerOfLine];
    if (separator) {
    }
    NSString *token = nil;
    if ( [scannerOfLine scanCharactersFromSet:gAllButColonCharacterSet
                                   intoString:&token] ) {
        NSTimeZone *tz = [NSTimeZone timeZoneWithName:token];
        [self setTimeZone:tz];
    }
}

// Defines a list of date/times for the recurrence rule.
// RDATE:19970714T123000Z
// RDATE;TZID=US-EASTERN:19970714T083000
// RDATE;VALUE=PERIOD:19960403T020000Z/19960403T040000Z,19960404T010000Z/PT3H
// RDATE;VALUE=DATE:19970101,19970120,19970217,19970421
- (void)ruleRDATE:(NSScanner *)scannerOfLine {
    NSString *token;
    while (nil != (token = [self parseToken:scannerOfLine])) {
        // TODO: Finish this up.
    }
}

// typical: RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20060804T180000Z;WKST=SU
// or: RRULE:FREQ=YEARLY;INTERVAL=1
- (void)ruleRRULE:(NSScanner *)scannerOfLine {
    while (0 < [[scannerOfLine string] length]) {
        NSString *token = [self parseToken:scannerOfLine];
        NSString *separator = [self parseToken:scannerOfLine];
        if (separator) {
        }
        NSValue *val = [gRecurrenceKeywordDict objectForKey:token];
        if (val) {
            [self performSelector:[val pointerValue] withObject:scannerOfLine];
        } else {
            break;
        }
    }
}


// Handle: BYDAY=MO,WE,FR
// Handle: BYDAY=2MO
- (void)recurBYDAY:(NSScanner *)scannerOfLine {
    NSString *token;
    NSMutableArray *dayList = nil;
    while (nil != (token = [self parseToken:scannerOfLine]) && ! [@";" isEqual:token]) {
        unichar c = [token characterAtIndex:0];
        if (('0' <= c && c <= '9') || '-' == c) {
            int n = [token intValue];
            [self setOutputObject:[NSArray arrayWithObject:[NSNumber numberWithInt:n]] forKey:kRecurrenceByDayFreq];
            token = [self parseToken:scannerOfLine];
            // TODO: multiple numbers are allowed (comma separated?)
        }
        NSString *icalDay = [gRecurrenceDayOfWeekDict objectForKey:token];
        if (icalDay) {
            if (dayList) {
                [dayList addObject:icalDay];
            } else {
                dayList = [NSMutableArray arrayWithObject:icalDay];
            }
            token = [self parseToken:scannerOfLine];
            if ( ! [@"," isEqual:token]) {  // expect comma separation.
                break;
            }
        } else {
            NSLog(@"recurBYDAY can't parse \"%@\"", [scannerOfLine string]);
            break;
        }
    }
    if (dayList) {
        [self setOutputObject:dayList forKey:kRecurrenceByDayDays];
    }
    if ( ! [@";" isEqual:token]) {
        [self skipPastSemicolon:scannerOfLine];
    }
}

- (void)recurBYMONTH:(NSScanner *)scannerOfLine {
    NSArray *list;
    if (nil != (list = [self parseIntegerArrayClause:scannerOfLine low:1 high:12])) {
        [self setOutputObject:list forKey:kRecurrenceByMonth];
    }
}

- (void)recurBYSETPOS:(NSScanner *)scannerOfLine {
    NSArray *list;
    if (nil != (list = [self parseIntegerArrayClause:scannerOfLine low:1 high:INT_MAX])) {
        [self setOutputObject:list forKey:kRecurrenceBySetPos];
    }
}


- (void)recurBYWEEK:(NSScanner *)scannerOfLine {
    NSArray *list;
    if (nil != (list = [self parseIntegerArrayClause:scannerOfLine low:-53 high:53])) {
        [self setOutputObject:list forKey:kRecurrenceByWeekNumber];
    }
}

- (void)recurBYYEAR:(NSScanner *)scannerOfLine {
    NSArray *list;
    if (nil != (list = [self parseIntegerArrayClause:scannerOfLine low:-366 high:366])) {
        [self setOutputObject:list forKey:kRecurrenceByYearDay];
    }
}

- (void)recurFREQ:(NSScanner *)scannerOfLine {
    NSString *units = [self parseToken:scannerOfLine];
    NSString *icalUnits;
    if (units && nil != (icalUnits = [gRecurrenceUnitsDict objectForKey:units])) {
        [self setOutputObject:icalUnits forKey:kRecurrenceFrequencyKey];
        [self skipPastSemicolon:scannerOfLine];
    } else if ( ! [@";" isEqual:units]) {
        [self skipPastSemicolon:scannerOfLine];
    }
}

- (void)recurINTERVAL:(NSScanner *)scannerOfLine {
    NSNumber *intNumber = [self parseIntegerClause:scannerOfLine];
    if (intNumber) {
        [self setOutputObject:intNumber forKey:kRecurrenceIntervalKey];
    }
}

// typical: UNTIL=20060804T180000Z
- (void)recurUNTIL:(NSScanner *)scannerOfLine {
    id date = [self parseDate:scannerOfLine];
    if (date) {
        [self setOutputObject:date forKey:kRecurrenceUntilKey];
    }
    if ( ! ([scannerOfLine scanLocation] &&
            ';' == [[scannerOfLine string] characterAtIndex:[scannerOfLine scanLocation] - 1])) {
        [self skipPastSemicolon:scannerOfLine];
    }
}

- (void)recurWKST:(NSScanner *)scannerOfLine {
    NSString *wkst = [self parseToken:scannerOfLine];
    NSString *weekday;
    if (wkst && nil != (weekday = [gRecurrenceDayOfWeekDict objectForKey:wkst])) {
        [self setOutputObject:weekday forKey:kRecurrenceWeekStartDayKey];
        [self skipPastSemicolon:scannerOfLine];
    } else if ( ! [@";" isEqual:wkst]) {
        [self skipPastSemicolon:scannerOfLine];
    }
}

- (void)recurCOUNT:(NSScanner *)scannerOfLine {
    NSNumber *intNumber = [self parseIntegerClause:scannerOfLine];
    if (intNumber) {
        [self setOutputObject:intNumber forKey:kRecurrenceCountKey];
    }
}

- (void)recurBYSECOND:(NSScanner *)scannerOfLine {
    NSArray *list;
    if (nil != (list = [self parseIntegerArrayClause:scannerOfLine low:1 high:INT_MAX])) {
        NSLog(@"recurBYSECOND can't parse: \"%@\"", [scannerOfLine string]);
        // TODO: are the seconds even multiples of days?
    }
}

- (void)recurBYMINUTE:(NSScanner *)scannerOfLine {
    NSArray *list;
    if (nil != (list = [self parseIntegerArrayClause:scannerOfLine low:1 high:INT_MAX])) {
        NSLog(@"recurBYMINUTE Can't parse: \"%@\"", [scannerOfLine string]);
        // TODO: are the minutes even multiples of days?
    }
}

- (void)recurBYHOUR:(NSScanner *)scannerOfLine {
    NSArray *list;
    if (nil != (list = [self parseIntegerArrayClause:scannerOfLine low:1 high:INT_MAX])) {
        NSLog(@"recurBYHOUR Can't parse: \"%@\"", [scannerOfLine string]);
        // TODO: are the hours even multiples of days?
    }
}

- (void)recurBYWEEKNO:(NSScanner *)scannerOfLine {
    NSArray *list;
    if (nil != (list = [self parseIntegerArrayClause:scannerOfLine low:-53 high:53])) {
        [self setOutputObject:list forKey:kRecurrenceByWeekNumber];
    }
}

- (void)recurBYMONTHDAY:(NSScanner *)scannerOfLine {
    NSArray *list;
    if (nil != (list = [self parseIntegerArrayClause:scannerOfLine low:-31 high:31])) {
        [self setOutputObject:list forKey:kRecurrenceByMonthDay];
    }
}

- (void)setTimeZone:(NSTimeZone *)timeZone {
    [timeZone_ autorelease];
    timeZone_ = [timeZone retain];
}

- (NSTimeZone *)timeZone {
    return timeZone_;
}

// return day of week as integer in range 0..6,  0 == sunday. -1 if not a day of week name.
// we don't care about case since, the sync services manager interface specifiers lower.
- (int)stringToDayOfWeek:(NSString *)weekdayS {
    int i;
    for(i = 0; i < 7; ++i) {
        if ([weekdayS isEqual:gDayOfWeek[i]]) {
            return i;
        }
    }
    return  -1;
}

// return YES if arguments are both legal, and startDate falls on weekday
- (BOOL)isOnSameWeekday:(NSString *)weekdayS startDate:(id)startDateS {
    GDataDateTime *start;
    if ([startDateS respondsToSelector:@selector(length)]) {
        start = [GDataDateTime dateTimeWithRFC3339String:startDateS];
    } else {
        start = startDateS;
    }
    int weekday = [self stringToDayOfWeek:weekdayS];
    int dayOfWeek = 0;
    if (start) {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents * components = [calendar components:NSWeekdayCalendarUnit fromDate:[start date]];
        dayOfWeek = [components weekday]-1;
    }
    return start && (weekday == dayOfWeek);
}

// A sample dict where we'd return NO is the following:
// { bydaydays: ["wednesday"],
//  end date:"2007-04-17T08:00:00-07:00",
//  start date:"2007-04-17T07:00:00-07:00",
//  frequency:"weekly"}
// because 2007-04-17 is a tuesday.
// for undefined or bad arguments, it is sufficient to return YES, since this a
// private method.
-(BOOL)isStartOnSameWeekday:(NSDictionary *)dict {
    BOOL val = YES;
    if ([[dict objectForKey:kRecurrenceFrequencyKey] isEqual:kWeeklyValue]) {    
        NSArray *days = [dict objectForKey:kRecurrenceByDayDays];
        if (1 == [days count]) {
            NSString *weekday = [days objectAtIndex:0];
            NSString *startDate = [dict objectForKey:kStartDateKey];
            if (weekday && startDate) {
                val = [self isOnSameWeekday:weekday startDate:startDate];
            }
        }
    }
    return val;
}

// CL 635950 iCal has a bug where it doesn't like lists length 1 here.
// change to a simple: recurs every week.
// Except: if frequency is weekly and the start date falls on a different day of
// the week
// inverse of isToStringLength1Exception:  -- below
- (BOOL)isToDictLength1Exception:(NSDictionary *)dict {
    NSArray *days = [dict objectForKey:kRecurrenceByDayDays];
    BOOL val = (1 == [days count]);
    if (val) {
        val = [self isStartOnSameWeekday:dict];
    }
    return val;
}

// inverse of isToDictLength1Exception: Note: the asymmetry between this and its
// inverse is intentional
- (BOOL)isToStringLength1Exception:(NSDictionary *)dict {
    BOOL val = (1 == [[dict objectForKey:kRecurrenceIntervalKey] intValue]);
    return val;
}

// Note 1: When parsing a string into a NSDictionary for Sync Services,
// the string RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR we must supplement:
// <key>frequency</key><string>weekly</string>
// by
// <key>bydayfreq</key><array><number>0</number><number>0</number></array>
// (where the length of the bydayfreq array is the same as the kRecurrenceByDayDays)
// and remove them for the inverse transform.
//
// See Note 1 above. Fix naive parse. 
- (void)prepareForGenerateDictionary:(NSMutableDictionary *)dict {
    NSArray *days = [dict objectForKey:kRecurrenceByDayDays];
    NSString *recurrenceFrequency = [dict objectForKey:kRecurrenceFrequencyKey];
    if (days && [days respondsToSelector:@selector(count)] &&
        ([recurrenceFrequency isEqual:kWeeklyValue] || [recurrenceFrequency isEqual:kDailyValue])) {
        
        if ([self isToDictLength1Exception:dict]) {
            [dict removeObjectForKey:kRecurrenceByDayDays];
        } else {
            if ([[dict objectForKey:kRecurrenceFrequencyKey] isEqual:kDailyValue]) {
                [dict setObject:kWeeklyValue forKey:kRecurrenceFrequencyKey];
            }
            NSMutableArray *recurrences = [NSMutableArray array];
            int i, iCount = [days count];
            for (i = 0; i < iCount; ++i) {
                [recurrences addObject:[NSNumber numberWithInt:0]];
            }
            [dict setObject:recurrences forKey:kRecurrenceByDayFreq];
        }
        if (nil == [dict objectForKey:kRecurrenceIntervalKey]) {
            [dict setObject:[NSNumber numberWithInt:1] forKey:kRecurrenceIntervalKey];
        }
    }
}

// See Note 1 above. Reverse the transform in prepareForGenerateDictionary
- (NSDictionary *)prepareForGenerateString:(NSDictionary *)dict {
    NSArray *recurrences = [dict objectForKey:kRecurrenceByDayFreq];
    NSArray *days = [dict objectForKey:kRecurrenceByDayDays];
    NSNumber *n = nil;
    if (days && recurrences && 
        [days respondsToSelector:@selector(count)] &&
        [recurrences respondsToSelector:@selector(count)] &&
        [days count] == [recurrences count] && 
        nil != (n = [recurrences objectAtIndex:0]) &&
        [n respondsToSelector:@selector(intValue)] && 
        0 == [n intValue]) {
        
        NSMutableDictionary *mdict = [[dict mutableCopy] autorelease];
        [mdict setObject:kWeeklyValue forKey:kRecurrenceFrequencyKey];
        [mdict removeObjectForKey:kRecurrenceByDayFreq];
        if ([self isToStringLength1Exception:mdict]) {
            [mdict removeObjectForKey:kRecurrenceIntervalKey];
        }
        return mdict;
    }
    return dict;
}

@end
