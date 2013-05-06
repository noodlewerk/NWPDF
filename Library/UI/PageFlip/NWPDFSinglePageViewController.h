//
//  NWPDFSinglePageViewController.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NWPDFPage;
@class NWPDFSinglePageView;

@interface NWPDFSinglePageViewController : UIViewController
- (id)initWithPDFPage:(NWPDFPage*)page;
@property (nonatomic, readonly) NWPDFPage* page;
@property (nonatomic, readonly) NWPDFSinglePageView* pageView;
@end
