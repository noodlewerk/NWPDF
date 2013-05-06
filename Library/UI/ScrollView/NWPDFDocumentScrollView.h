//
//  NWPDFDocumentScrollView.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NWPDFSinglePageView.h"

@protocol NWPDFDocumentScrollViewDelegate;

@class NWPDFDocument, NWPDFPage;

@interface NWPDFDocumentScrollView : UIScrollView <NWPDFSinglePageViewDelegate>

@property (nonatomic, readonly) NSInteger currentPageIndex;
@property (nonatomic, assign) id <NWPDFDocumentScrollViewDelegate> pdfDocumentDelegate;
@property (nonatomic, readonly) NWPDFSinglePageZoomView *currentPageView;

- (id)initWithDocument:(NWPDFDocument *)document;
- (void)showPageAtIndex:(NSInteger)pageIndex animated:(BOOL)animated;
- (void)loadDocument:(NWPDFDocument *)document;

@end

@protocol NWPDFDocumentScrollViewDelegate <NSObject>
@optional
- (void)pdfDocumentScrollView:(NWPDFDocumentScrollView *)pdfDocumentScrollView willLoadPage:(NWPDFPage *)page onView:(NWPDFSinglePageZoomView *)pageView;
- (UIView *)pdfDocumentScrollView:(NWPDFDocumentScrollView *)pdfDocumentScrollView viewForAnnotation:(NWPDFAnnotation *)annotation;
@end
