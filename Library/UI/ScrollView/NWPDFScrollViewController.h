//
//  NWPDFScrollViewController.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NWPDFDocumentScrollView.h"
#import "NWPDFThumbIndexView.h"

@protocol NWPDFScrollViewControllerDelegate;

@class NWPDFDocument, NWPDFPageNumberView;

@interface NWPDFScrollViewController : UIViewController <UIGestureRecognizerDelegate, NWPDFDocumentScrollViewDelegate, NWPDFThumbIndexViewDelegate>

@property (nonatomic, readonly) NWPDFDocument *document;
@property (nonatomic, readonly) NWPDFPageNumberView *pageNumberView;
@property (nonatomic, readonly) NWPDFDocumentScrollView *documentView;
@property (nonatomic, readonly) BOOL controlsHidden;
@property (nonatomic, readonly) UIToolbar *toolbar;
@property (nonatomic, assign) id<NWPDFScrollViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL showCacheMonitor;

- (id)initWithDocument:(NWPDFDocument *)document cacheName:(NSString *)cacheName pageIndex:(NSUInteger)pageIndex;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)writeCacheToDisk;

@end

@protocol NWPDFScrollViewControllerDelegate <NSObject>
@optional
- (UIView *)pdfScrollViewController:(NWPDFScrollViewController *)pdfScrollViewController viewForAnnotation:(NWPDFAnnotation *)annotation;
- (void)pdfScrollViewController:(NWPDFScrollViewController *)pdfScrollViewController controlsHidden:(BOOL)hidden;
@end
