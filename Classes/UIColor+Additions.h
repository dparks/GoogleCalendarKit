//
//  UIColor+Additions.h
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/08/21.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIColor(Additions)
- (UIColor *)initWithHex:(NSString *)hex alpha:(CGFloat)alpha;
+ (UIColor *)settingTextColor;
@end
