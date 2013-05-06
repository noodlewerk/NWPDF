//
//  NWPDFThumbIndexView.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFThumbIndexView.h"
#import "NWPDFDocument.h"
#import <QuartzCore/QuartzCore.h>
#import "NWPDFPage.h"
#import "NWPDFThumbPrefetcher.h"

@implementation NWPDFThumbIndexView {
    NWPDFDocument *document;
    NSMutableArray *thumbViews;
    NSInteger selectedPageIndex;
}
@synthesize delegate, maximumThumbnails, prefetcher;

- (id)initWithDocument:(NWPDFDocument *)_document cache:(NWPDFCache *)cache
{
    self = [super init];
    if (self) {
        document = _document;
        maximumThumbnails = 35;
        NSInteger count = MIN(maximumThumbnails, document.pageCount);
        prefetcher = [[NWPDFThumbPrefetcher alloc] initWithCache:cache size:CGSizeMake(50 * 4, 50 * 4) count:count];
        [prefetcher prefetchForRange:NSMakeRange(0, MIN(document.pageCount, 10))];
        thumbViews = [NSMutableArray arrayWithCapacity:count];

     //   CGFloat skipRatio = (float)document.pageCount / (float)count;
        for(NSInteger i=0; i<count; i++){
            UIImageView *thumbView = [[UIImageView alloc] initWithFrame:CGRectZero];
            thumbView.backgroundColor = [UIColor whiteColor];
            thumbView.layer.borderColor = [UIColor lightGrayColor].CGColor;
            thumbView.layer.borderWidth = 1;
            [prefetcher thumbForIndex:i block:^(UIImage *image){
                thumbView.image = image;
            }];

            [self addSubview:thumbView];
            [thumbViews addObject:thumbView];
        }
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat height = self.bounds.size.height * 0.6;
    CGFloat width = self.bounds.size.width / thumbViews.count;
    width = MIN(width, height);
    
    CGFloat heightOffset = (self.bounds.size.height - height) / 2;
    CGFloat widthOffset = (self.bounds.size.width - thumbViews.count * width) / 2;

    for (NSUInteger i = 0; i < thumbViews.count; i++) {
        UIView *thumbView = [thumbViews objectAtIndex:i];
        NWPDFPage *page = [document pageAtIndex:[prefetcher pageForIndex:i]];
        CGRect rect = [page pageWithin:CGSizeMake(width, height)];
        rect.origin.x += width * i + widthOffset;
        rect.origin.y += heightOffset;
        CGRect frame = CGRectIntegral(CGRectInset(rect, 1, 1));
        thumbView.frame = frame;
    }
}

- (NSUInteger)pageIndexForTouches:(NSSet *)touches
{
    CGFloat height = self.bounds.size.height * 0.6;
    CGFloat width = self.bounds.size.width / thumbViews.count;
    width = MIN(width, height);
    CGFloat widthOffset = (self.bounds.size.width - (thumbViews.count - 1) * width) / 2;
    
    NSInteger pageCount = document.pageCount;
    CGPoint location = [touches.anyObject locationInView:self];
    NSInteger i = roundf((location.x - widthOffset) / width / (thumbViews.count - 1) * pageCount);
    NSUInteger result = MAX(MIN(i, pageCount - 1), 0);
    return result;
}

- (void)flipToPage:(NSSet *)touches
{
    NSUInteger index = [self pageIndexForTouches:touches];
    if (selectedPageIndex != index) {
        selectedPageIndex = index;
        if ([delegate respondsToSelector:@selector(thumbIndexView:didSelectThumbAtIndex:)]) {
            [delegate thumbIndexView:self didSelectThumbAtIndex:index];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(flipToPage:) withObject:touches afterDelay:0.0];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(flipToPage:) withObject:touches afterDelay:0.5];
    if ([delegate respondsToSelector:@selector(thumbIndexView:didSelectThumbAtIndex:)]) {
        NSUInteger index = [self pageIndexForTouches:touches];
        [delegate thumbIndexView:self didScrollThumbAtIndex:index];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(flipToPage:) withObject:touches afterDelay:0.0];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:nil];
}

@end