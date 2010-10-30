//
//  UIColor+Additions.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/08/21.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "UIColor+Additions.h"

static UIColor *settingTextColor;

@implementation UIColor(Additions)

- (UIColor *)initWithHex:(NSString *)hex alpha:(CGFloat)alpha {
    UIColor *color = nil;
    if (hex && [hex length] == 7) {
        NSString *colorString = [NSString stringWithFormat:
                                 @"0x%@ 0x%@ 0x%@",
                                 [hex substringWithRange:NSMakeRange(1, 2)],
                                 [hex substringWithRange:NSMakeRange(3, 2)],
                                 [hex substringWithRange:NSMakeRange(5, 2)]];
        
        unsigned red, green, blue;
        NSScanner *scanner = [NSScanner scannerWithString:colorString];
        if ([scanner scanHexInt:&red] && [scanner scanHexInt:&green] && [scanner scanHexInt:&blue]) {
            color = [[UIColor alloc] initWithRed:(float)red / 0xff
                                           green:(float)green / 0xff
                                            blue:(float)blue / 0xff
                                           alpha:alpha];
        }
    }
    return color;
}

+ (UIColor *)settingTextColor {
    if (!settingTextColor) {
        settingTextColor = [[UIColor colorWithRed:0.20f green:0.30f blue:0.49f alpha:1.0f] retain];
    }
    return settingTextColor;
}

@end
