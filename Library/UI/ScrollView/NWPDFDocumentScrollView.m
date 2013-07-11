//
//  NWPDFDocumentScrollView.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFDocumentScrollView.h"
#import "NWPDFDocument.h"
#import "NWPDFSinglePageView.h"
#import "NWPDFPage.h"
#import "NWLCore.h"


@implementation NWPDFDocumentScrollView {
    NWPDFDocument *document;
    NWPDFSinglePageZoomView *pageViewEven;
    NWPDFSinglePageZoomView *pageViewOdd;
}

@synthesize currentPageIndex, pdfDocumentDelegate;

- (void)setup {
    self.pagingEnabled = YES;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.backgroundColor = [UIColor clearColor];
    
    currentPageIndex = 0;
    self.contentMode = UIViewContentModeCenter;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithDocument:(NWPDFDocument *)_document
{
    self = [super init];
    if (self) {
        document = _document;
        [self setup];
    }
    return self;
}

- (void)loadDocument:(NWPDFDocument *)_document {
    document = _document;
    [self setNeedsLayout];
}

- (NWPDFSinglePageZoomView *)currentPageView
{
    CGPoint center = self.contentOffset;
    center.x += CGRectGetMidX(self.frame);
    center.y = CGRectGetMidY(self.frame);

    if(CGRectContainsPoint(pageViewEven.frame, center)){
        return pageViewEven;
    }
    if(CGRectContainsPoint(pageViewOdd.frame, center)){
        return pageViewOdd;
    }
    
    return nil;
}

- (CGRect)rectForPage:(NWPDFPage *)page
{
    CGFloat width = self.bounds.size.width;
    CGRect rect = self.bounds;
    rect.origin.x = page.index * width;
    rect.origin.y = 0;
    return CGRectIntegral(rect);
}

- (void)loadPageAtIndex:(NSInteger)index {
    CGRect mainInterSectRect = self.bounds;
    mainInterSectRect.origin.x = index * self.bounds.size.width;
    
    BOOL intersects = CGRectIntersectsRect(self.bounds, mainInterSectRect);

    NWPDFSinglePageZoomView *pageView = index % 2 == 0 ? pageViewEven : pageViewOdd;

    if((!pageView || pageView.page.index != index) && intersects){
        NWPDFPage *page = [document pageAtIndex:index];
        if(!page){
            NWLogWarn(@"Huh");
        }
        NWLogDbug(@"Rendering page with index: %i", index);
        [pageView removeFromSuperview];
        pageView = [[NWPDFSinglePageZoomView alloc] initWithPage:page annotationDelegate:self];
        if([pdfDocumentDelegate respondsToSelector:@selector(pdfDocumentScrollView:willLoadPage:onView:)]){
            [pdfDocumentDelegate pdfDocumentScrollView:self willLoadPage:page onView:pageView];
        }
        [self addSubview:pageView];
        if(index % 2 == 0){
            pageViewEven = pageView;
        } else {
            pageViewOdd = pageView;
        }
        
    }

    CGRect rect = [self rectForPage:pageView.page];
    pageView.frame = rect;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat xOffset = self.contentOffset.x;
    CGFloat width = self.bounds.size.width;

    // Page Index
    NSInteger newPageIndex = (int)round(xOffset / width);
    if(newPageIndex != currentPageIndex){
        [self willChangeValueForKey:@"currentPageIndex"];
        currentPageIndex = newPageIndex;
        [self didChangeValueForKey:@"currentPageIndex"];
    }

    NSInteger currentPageI = (int)floor(xOffset / width);
    
    if(currentPageI >= 0 && currentPageI < document.pageCount){
        [self loadPageAtIndex:currentPageI];
        if(currentPageI < (document.pageCount - 1)){
            [self loadPageAtIndex:currentPageI + 1];
        }
    }
}

- (void)setFrame:(CGRect)frame
{
    BOOL sizeChanging = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    NWPDFSinglePageZoomView *currentPageView = [self currentPageView];
    [super setFrame:frame];
    self.contentSize = CGSizeMake(document.pageCount * self.bounds.size.width, 0);
   
    if (sizeChanging) {
        CGRect mainRect = self.bounds;
        mainRect.origin.x = currentPageView.page.index * self.bounds.size.width;
        if(currentPageView){
            self.contentOffset = CGPointMake(mainRect.origin.x, 0);
        }
        // Set frame
        CGRect rect = [self rectForPage:pageViewEven.page];
        pageViewEven.frame = rect;
        rect = [self rectForPage:pageViewOdd.page];
        pageViewOdd.frame = rect;
    }
}

#pragma mark - 

- (void)showPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated
{
    [self setContentOffset:CGPointMake(pageIndex * self.bounds.size.width, 0) animated:animated];
}

#pragma mark - NWPDFSinglePageView Delegate

- (UIView *)pageView:(NWPDFSinglePageView *)pageView viewForAnnotation:(NWPDFAnnotation *)annotation {
    if([pdfDocumentDelegate respondsToSelector:@selector(pdfDocumentScrollView:viewForAnnotation:)]){
        return [pdfDocumentDelegate pdfDocumentScrollView:self viewForAnnotation:annotation];
    } else {
        UIView *aView = [[UIView alloc] initWithFrame:CGRectZero];
        aView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.6];
        return aView;
    }
}

@end