//
//  NWPDFScrollViewController.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFScrollViewController.h"
#import "NWPDFPageNumberView.h"
#import "NWPDFDocument.h"
#import "NWPDFPage.h"
#import "NWPDFPagePrefetcher.h"
#import "NWPDFCache.h"
#import "NWPDFSinglePageView.h"
#import "NWPDFThumbPrefetcher.h"
#import "NWPDFCacheMonitorView.h"
#import "NWLCore.h"


@class NWPDFDocument;

@implementation NWPDFScrollViewController {
    UIToolbar *toolbar;
    
    NWPDFCache *pageCache;
    NWPDFCache *thumbCache;
    NWPDFPagePrefetcher *pagePrefecher;
    NWPDFThumbPrefetcher *thumbPrefetcher;
    
    NWPDFThumbIndexView *thumbIndexView;
    NSString *cacheName;
    NSUInteger startPage;
}

@synthesize document, pageNumberView, documentView, controlsHidden, delegate, showCacheMonitor;

- (id)init
{
    self = [super init];
    if (self) {
        NWLogWarn(@"Do not use init, use initWithDocument instead");
    }
    return self;
}

- (id)initWithDocument:(NWPDFDocument *)_document cacheName:(NSString *)_cacheName pageIndex:(NSUInteger)_startPage
{
    self = [super init];
    if (self) {
        document = _document;        
        cacheName = _cacheName;
        startPage = _startPage;
    
        controlsHidden = YES;
        
        pageCache = [[NWPDFCache alloc] initWithDocument:_document];
        pageCache.memoryCacheSizeMax = 40 * 1000 * 1000;
        [pageCache readFromCacheWithName:[cacheName stringByAppendingString:@"-page"]];
        thumbCache = [[NWPDFCache alloc] initWithDocument:_document];
        thumbCache.memoryCacheSizeMax = 10 * 1000 * 1000;
        [thumbCache readFromCacheWithName:[cacheName stringByAppendingString:@"-thumb"]];
        pagePrefecher = [[NWPDFPagePrefetcher alloc] initWithCache:pageCache size:CGSizeMake(800, 800)];
    }
    return self;
}

#pragma mark - View Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    thumbIndexView = [[NWPDFThumbIndexView alloc] initWithDocument:document cache:thumbCache];
    thumbIndexView.delegate = self;
    thumbPrefetcher = thumbIndexView.prefetcher;

    documentView = [[NWPDFDocumentScrollView alloc] initWithDocument:document];
    documentView.pdfDocumentDelegate = self;
    
    [documentView addObserver:self forKeyPath:@"currentPageIndex" options:0 context:0];
    documentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    documentView.frame = self.view.bounds;
    [self.view addSubview:documentView];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleControls:)];
    gesture.delegate = self;
    [self.view addGestureRecognizer:gesture];
    
    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
    if (showCacheMonitor) {
        NWPDFCacheMonitorView *pageMonitor = [[NWPDFCacheMonitorView alloc] initWithFrame:CGRectMake(20, 10, self.view.bounds.size.width - 40, 20) name:@"page"];
        pageMonitor.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:pageMonitor];
        pageCache.monitor.delegate = pageMonitor;
        
        NWPDFCacheMonitorView *thumbMonitor = [[NWPDFCacheMonitorView alloc] initWithFrame:CGRectMake(20, 40, self.view.bounds.size.width - 40, 20) name:@"thumb"];
        thumbMonitor.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:thumbMonitor];
        thumbCache.monitor.delegate = thumbMonitor;
    }
    
    self.toolbar.translucent = YES;
    toolbar.alpha = 0.0;
    [self.view addSubview:toolbar];
    
    thumbIndexView.frame = CGRectInset(toolbar.bounds, 100, 0);
    thumbIndexView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:thumbIndexView];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    toolbar.items = @[flex, barItem, flex];
    
    CGRect rect = CGRectMake(self.view.bounds.size.width / 2 - 40, self.view.bounds.size.height - 100, 80, 25);
    pageNumberView = [[NWPDFPageNumberView alloc] initWithFrame:rect];
    pageNumberView.pageCount = document.pageCount;
    pageNumberView.pageNumber = documentView.currentPageIndex + 1;
    [self.view addSubview:pageNumberView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [documentView showPageAtIndex:startPage animated:NO];
    UIImage *image = [pageCache readFromCacheWithName:[cacheName stringByAppendingString:@"-page"] page:startPage];

    // Force currentPageView to load
    if(!documentView.currentPageView){
        [documentView layoutSubviews];
    }
    [documentView.currentPageView setImage:image];
}

- (void)viewDidUnload
{
    [self cleanup];
    [super viewDidUnload];
}

- (void)cleanup
{
    [self writeCacheToDisk];
    [documentView removeObserver:self forKeyPath:@"currentPageIndex"];
    toolbar = nil;
    pageNumberView = nil;
    thumbIndexView = nil;
    document = nil;
}

- (void)dealloc
{
    [self cleanup];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [pageCache reduceCacheSizeWithFactor:.5];
    [thumbCache reduceCacheSizeWithFactor:.5];
}


#pragma mark - Getters

- (UIToolbar *)toolbar {
    if(!toolbar){
        toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44)];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    return toolbar;
}

- (NWPDFDocument *)document {
    return document;
}

#pragma mark - Actions

- (void)writeCacheToDisk
{
    [pageCache writeToCacheWithName:[cacheName stringByAppendingString:@"-page"] quality:.8];
    [thumbCache writeToCacheWithName:[cacheName stringByAppendingString:@"-thumb"] quality:.8];
}

- (void)setControlsHidden:(BOOL)hide animated:(BOOL)animated
{
    controlsHidden = hide;
    
    [UIView animateWithDuration:animated ? 0.4 : 0.0 animations:^{
        toolbar.alpha = hide ? 0.0 : 1.0;
        pageNumberView.alpha = hide ? 0.0 : 1.0;
    }];
}

- (void)toggleControls:(UITapGestureRecognizer *)gesture
{
    if(gesture.state == UIGestureRecognizerStateRecognized){
        controlsHidden = !controlsHidden;
        if([delegate respondsToSelector:@selector(pdfScrollViewController:controlsHidden:)]){
            [delegate pdfScrollViewController:self controlsHidden:controlsHidden];
        } else {
            [self setControlsHidden:controlsHidden animated:YES];
        }
    }
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint location = [touch locationInView:self.view];
    if(CGRectContainsPoint(toolbar.frame, location)){
        return NO;
    }
    BOOL shouldReceiveTouch = YES;
    for(UIView <NWPDFAnnotationView>*annotationView in documentView.currentPageView.annotationViews){
        if([annotationView respondsToSelector:@selector(shouldReceiveTouchForLocation:)]){
            CGPoint convertedLocation = [touch locationInView:annotationView];
            convertedLocation.x -= documentView.bounds.size.width * documentView.currentPageIndex;
            BOOL annotationViewTouched = [annotationView shouldReceiveTouchForLocation:convertedLocation];
            if(annotationViewTouched){
                shouldReceiveTouch = NO;
                continue;
            }
        }
    }
    return shouldReceiveTouch;
}

#pragma mark - NWPDFDocumentScrollViewDelegate

- (void)pdfDocumentScrollView:(NWPDFDocumentScrollView *)pdfDocumentScrollView willLoadPage:(NWPDFPage *)page onView:(NWPDFSinglePageView *)pageView {    
    UIImage *image = [pageCache imageFromCacheForPage:page.index];
    if (!image) {
        image = [thumbCache imageFromCacheForPage:page.index];
    }
    [pagePrefecher prefetchFor:page.index];
    [thumbPrefetcher prefetchFor:page.index];
    [pageView setImage:image];
}

- (UIView *)pdfDocumentScrollView:(NWPDFDocumentScrollView *)pdfDocumentScrollView viewForAnnotation:(NWPDFAnnotation *)annotation;
{
    if([delegate respondsToSelector:@selector(pdfScrollViewController:viewForAnnotation:)]){
        return [delegate pdfScrollViewController:self viewForAnnotation:annotation];
    }
    return nil;
}

#pragma mark - NWPDFThumbIndexViewDelegate

- (void)thumbIndexView:(NWPDFThumbIndexView *)thumbIndexView didSelectThumbAtIndex:(NSInteger)index {
    [documentView showPageAtIndex:index animated:NO];
}

- (void)thumbIndexView:(NWPDFThumbIndexView *)thumbIndexView didScrollThumbAtIndex:(NSInteger)index {
    pageNumberView.pageNumber = index + 1;
}

#pragma mark - Misc

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"currentPageIndex"]){
        pageNumberView.pageNumber = documentView.currentPageIndex + 1;
    }
}

@end