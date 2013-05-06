//
//  NWPDFSinglePageViewController.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFSinglePageViewController.h"
#import "NWPDFSinglePageView.h"

@implementation NWPDFSinglePageViewController {
    NWPDFPage *page;
    NWPDFSinglePageView *pageView;
}
@synthesize page, pageView;

- (id)initWithPDFPage:(NWPDFPage*)_page
{
    self = [super init];
    if (self) {
        page = _page;
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    pageView = [[NWPDFSinglePageView alloc] initWithPage:page annotationDelegate:nil];
    pageView.frame = self.view.bounds;
    pageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:pageView];
}

@end
