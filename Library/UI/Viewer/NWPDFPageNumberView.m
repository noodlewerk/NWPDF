//
//  NWPDFPageNumberView.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFPageNumberView.h"
#import <QuartzCore/QuartzCore.h>

@implementation NWPDFPageNumberView {
    UILabel *pageNumberLabel;
}

@synthesize pageCount, pageNumber;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin  | UIViewAutoresizingFlexibleRightMargin;
        
        pageNumberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        pageNumberLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        pageNumberLabel.textColor = [UIColor whiteColor];
        pageNumberLabel.font = [UIFont boldSystemFontOfSize:12];
        pageNumberLabel.textAlignment = NSTextAlignmentCenter;
        pageNumberLabel.shadowColor = [UIColor blackColor];
        pageNumberLabel.shadowOffset = CGSizeMake(0, 1);
        
        pageNumberLabel.layer.cornerRadius = 3;
        [self addSubview:pageNumberLabel];
        
        CGRect shadowRect = CGRectInset(self.bounds, 2, 0);
        shadowRect.size.height = 3;
        shadowRect.origin.y = self.bounds.size.height - 4;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowRadius = 1;
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowRect].CGPath;
        self.layer.shadowOpacity = 0.5;
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    pageNumberLabel.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height - 3);
}

- (void)setPageNumber:(NSUInteger)_pageNumber{
    pageNumber = _pageNumber;
    pageNumberLabel.text = [NSString stringWithFormat:@"%i of %i", pageNumber, pageCount];
}

@end