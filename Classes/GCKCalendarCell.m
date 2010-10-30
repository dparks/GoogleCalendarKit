//
//  GCKCalendarCell.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKCalendarCell.h"

static UIFont *titleFont;
static UIFont *dateFont;

@interface GCKCalendarCellContentView : UIView {
    GCKCalendarCell *cell;
    BOOL highlighted;
}

@end

@implementation GCKCalendarCellContentView

+ (void)initialize {
    titleFont = [[UIFont boldSystemFontOfSize:17.0f] retain];
    dateFont = [[UIFont systemFontOfSize:13.0f] retain];
}

- (id)initWithFrame:(CGRect)frame cell:(GCKCalendarCell *)tableCell {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        cell = tableCell;
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)drawRect:(CGRect)rect {
    if (cell.syncState) {
        highlighted ? [[UIColor whiteColor] set] : cell.selectable ? [[UIColor blackColor] set] : [[UIColor grayColor] set];
        [cell.title drawInRect:CGRectMake(42.0f, 2.0f, cell.frame.size.width - 84.0f, 22.0f) withFont:titleFont lineBreakMode:UILineBreakModeTailTruncation];
        
        highlighted ? [[UIColor whiteColor] set] : [[UIColor grayColor] set];
        [cell.syncState drawInRect:CGRectMake(42.0f, 24.0f, cell.frame.size.width - 84.0f, 14.0f) withFont:dateFont lineBreakMode:UILineBreakModeTailTruncation];
    } else {
        highlighted ? [[UIColor whiteColor] set] : cell.selectable ? [[UIColor blackColor] set] : [[UIColor grayColor] set];
        [cell.title drawInRect:CGRectMake(42.0f, 10.0f, cell.frame.size.width - 84.0f, 22.0f) withFont:titleFont lineBreakMode:UILineBreakModeTailTruncation];
    }
    
    [cell.color set];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(6.0f, 6.0f, 29.0f, 29.0f) cornerRadius:6.0f];
    [path fill];
}

- (void)setHighlighted:(BOOL)b {
    highlighted = b;
    [self setNeedsDisplay];
}

- (BOOL)isHighlighted {
    return highlighted;
}

@end

@implementation GCKCalendarCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor whiteColor];
        cellContentView = [[GCKCalendarCellContentView alloc] initWithFrame:CGRectInset(self.contentView.bounds, 0.0f, 1.0f) cell:self];
        cellContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        cellContentView.contentMode = UIViewContentModeRedraw;
        [self.contentView addSubview:cellContentView];
        [cellContentView release];
        
        self.selectable = YES;
    }
    return self;
}

- (void)dealloc {
    self.title = nil;
    self.color = nil;
    [super dealloc];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [UIView setAnimationsEnabled:NO];
    CGSize contentSize = cellContentView.bounds.size;
    cellContentView.contentStretch = CGRectMake(225.0f / contentSize.width, 0.0f, (contentSize.width - 260.0f) / contentSize.width, 1.0f);
    [UIView setAnimationsEnabled:YES];
}

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    [cellContentView setNeedsDisplay];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
}

@end
