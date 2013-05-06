//
//  NWPDFPageContainerViewController.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NWPDFDocument;

@interface NWPDFPageContainerViewController : UIViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate>
- (id)initWithDocument:(NWPDFDocument *)document;
@end
