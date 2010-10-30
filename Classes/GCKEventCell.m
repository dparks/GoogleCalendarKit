//
//  GCKEventCell.m
//  GoogleCalendarKit
//
//  Created by Kishikawa Katsumi on 10/10/30.
//  Copyright 2010 Kishikawa Katsumi. All rights reserved.
//

#import "GCKEventCell.h"

static UIFont *titleFont;
static UIFont *dateFont;

@interface GCKEventCellContentView : UIView {
    GCKEventCell *cell;
    BOOL highlighted;
}

@end

@implementation GCKEventCellContentView

+ (void)initialize {
    titleFont = [[UIFont boldSystemFontOfSize:17.0f] retain];
    dateFont = [[UIFont boldSystemFontOfSize:14.0f] retain];
}

- (id)initWithFrame:(CGRect)frame cell:(GCKEventCell *)tableCell {
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
    highlighted ? [[UIColor whiteColor] set] : [[UIColor blackColor] set];
    [cell.startDate drawInRect:CGRectMake(24.0f, 12.0f, 50.0f, 22.0f) withFont:dateFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentRight];
    [cell.title drawInRect:CGRectMake(82.0f, 10.0f, cell.frame.size.width - 90.0f, 22.0f) withFont:titleFont lineBreakMode:UILineBreakModeTailTruncation];
    
    [cell.color set];
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(8.0f, 15.0f, 12.0f, 12.0f)];
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

@implementation GCKEventCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor whiteColor];
        cellContentView = [[GCKEventCellContentView alloc] initWithFrame:CGRectInset(self.contentView.bounds, 0.0f, 1.0f) cell:self];
        cellContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        cellContentView.contentMode = UIViewContentModeRedraw;
        [self.contentView addSubview:cellContentView];
        [cellContentView release];
    }
    return self;
}

- (void)dealloc {
    self.title = nil;
    self.color = nil;
    self.startDate = nil;
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
