//
//  NWPDFPage.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@class NWPDFDocument;

// An Objective-C wrapper for CGPDFPage.
@interface NWPDFPage : NSObject

// The wrapped CGPDFPage, allows access to the underlying datastructure.
@property (nonatomic, readonly) CGPDFPageRef ref;

// The parent document that has this page at 'index'.
@property (nonatomic, readonly) NWPDFDocument *document;

// The index of the page in 'document', starting at 0.
@property (nonatomic, readonly) NSUInteger index;

// A printable page index, starting at 1. Wraps CGPDFPageGetPageNumber.
@property (nonatomic, readonly) NSString *label;

// Page height over width, or 1 if the page has no area.
@property (nonatomic, readonly) CGFloat pageRatio;

// The printing angle: 0, 90, 180, or 270. Wraps CGPDFPageGetRotationAngle.
@property (nonatomic, readonly) NSInteger rotation;

// The content region in pdf coordinates. Wraps CGPDFPageGetBoxRect.
@property (nonatomic, readonly) CGRect pdfRect;

// Among other things, wraps CGPDFDocumentGetPage.
- (id)initWithDocument:(NWPDFDocument *)document index:(NSUInteger)index;

// Scales and draws the pdf page onto the frame in context.
- (void)drawInContext:(CGContextRef)context pageRect:(CGRect)frame;

// Transforms from view coords to PDF coords given the page's frame
- (CGRect)pdfRectFromViewRect:(CGRect)rect pageRect:(CGRect)frame;

// Transforms from PDF coords to view coords given the page's frame
- (CGRect)viewRectFromPDFRect:(CGRect)rect pageRect:(CGRect)frame;

// Returns a scaled page frame that fits the given box.
- (CGRect)pageWithin:(CGSize)maxSize;

// Returns the array of annotations.
- (NSArray *)extractAnnotations;

#if TARGET_OS_IPHONE
- (UIImage *)imageFromFrame:(CGRect)frame;
#endif

@end
