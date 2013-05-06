//
//  NWPDFSinglePageView.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>


@class NWPDFPage, NWPDFAnnotation, NWPDFSinglePageView;

@protocol NWPDFAnnotationView <NSObject>
@property (nonatomic, strong) NWPDFAnnotation *annotation;
@optional
- (BOOL)shouldReceiveTouchForLocation:(CGPoint)location;
@end

@interface NWPDFPageView : UIView
- (id)initWithFrame:(CGRect)frame page:(NWPDFPage *)page;
@end

@protocol NWPDFSinglePageViewDelegate <NSObject>
@optional
- (UIView <NWPDFAnnotationView>*)pageView:(NWPDFSinglePageView *)pageView viewForAnnotation:(NWPDFAnnotation *)annotation;
@end

@interface NWPDFSinglePageView : UIView

@property (nonatomic, readonly) NWPDFPage *page;
@property (nonatomic, readonly) NWPDFPageView *pdfView;
@property (nonatomic, readonly) id<NWPDFSinglePageViewDelegate>annotationDelegate;
@property (nonatomic, readonly) NSMutableArray *annotationViews;

- (id)initWithPage:(NWPDFPage *)page annotationDelegate:(id<NWPDFSinglePageViewDelegate>)annotationDelegate;
- (void)setImage:(UIImage *)image;

@end

@interface NWPDFSinglePageZoomView : UIScrollView <NWPDFSinglePageViewDelegate, UIScrollViewDelegate>

@property (nonatomic, readonly) NWPDFPage *page;
@property (nonatomic, readonly) id<NWPDFSinglePageViewDelegate>annotationDelegate;
@property (nonatomic, readonly) NSMutableArray *annotationViews;
@property (nonatomic, readonly) NWPDFPageView *pdfView;

- (id)initWithPage:(NWPDFPage *)page annotationDelegate:(id<NWPDFSinglePageViewDelegate>)annotationDelegate;
- (void)setImage:(UIImage *)image;

@end