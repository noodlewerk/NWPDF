//
//  NWPDFPage.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFPage.h"
#import "NWPDFDocument.h"
#import "NWPDFAnnotation.h"
#import "NWPDFCommon.h"
#import "NWPDFNode.h"


static NWPDFDisplayBox const NWPDFDefaultBox = kNWPDFDisplayBoxCropBox;


@implementation NWPDFPage {
    CGPDFDocumentRef documentRef;
}

@synthesize ref, pdfRect, document, index;


#pragma mark - Object lifecycle

- (id)initWithDocument:(NWPDFDocument *)_document index:(NSUInteger)_index
{
    self = [super init];
    if (self) {
        document = _document;
        documentRef = document.ref;
        // we keep ref to document, cuz apparently CGPDFPage needs its CGPDFDocument to function
        CGPDFDocumentRetain(documentRef);
        index = _index;
        ref = CGPDFDocumentGetPage(document.ref, index + 1);
        CGPDFPageRetain(ref);
        pdfRect = CGPDFPageGetBoxRect(ref, [NWPDFCommon cgBoxForDisplayBox:NWPDFDefaultBox]);
    }
    return self;
}

- (void)dealloc
{
    CGPDFPageRelease(ref);
    CGPDFDocumentRelease(documentRef);
}


#pragma mark - Basic properties

- (NSString *)label
{
    return [NSString stringWithFormat:@"%zu", CGPDFPageGetPageNumber(ref)];
}

- (NSInteger)rotation
{
    return CGPDFPageGetRotationAngle(ref);
}

- (CGFloat)pageRatio
{
    CGRect r = [self viewRectFromPDFRect:CGRectMake(0, 0, 1, 1) pageRect:CGRectMake(0, 0, 1, 1)];
    if (CGRectIsEmpty(r)) {
        return 1;
    }
    return r.size.width / r.size.height;
}


#pragma mark - Drawing and transforms

- (CGAffineTransform)viewToPDFTransformWithPageRect:(CGRect)frame
{
    if (CGRectIsEmpty(frame)) {
        return CGAffineTransformIdentity;
    }
    CGAffineTransform result = CGAffineTransformIdentity;
    result = CGAffineTransformTranslate(result, pdfRect.origin.x, -pdfRect.origin.y);
    result = CGAffineTransformTranslate(result, 0, -pdfRect.size.height);
    result = CGAffineTransformScale(result, pdfRect.size.width, pdfRect.size.height);
    result = CGAffineTransformTranslate(result, .5f, .5f);
    result = CGAffineTransformRotate(result, -self.rotation * M_PI / 180);
    result = CGAffineTransformTranslate(result, -.5f, -.5f);
    result = CGAffineTransformScale(result, 1 / frame.size.width, 1 / frame.size.height);
    return result;
}

- (CGRect)pdfRectFromViewRect:(CGRect)rect pageRect:(CGRect)frame
{
    rect = CGRectApplyAffineTransform(rect, [self viewToPDFTransformWithPageRect:frame]);
    rect.origin.y = -(rect.origin.y + rect.size.height);
    return rect;
}

- (CGAffineTransform)pdfToViewTransformWithPageRect:(CGRect)frame
{
    if (CGRectIsEmpty(pdfRect)) {
        return CGAffineTransformIdentity;
    }
    CGAffineTransform result = CGAffineTransformIdentity;
    result = CGAffineTransformScale(result, frame.size.width, frame.size.height);
    result = CGAffineTransformTranslate(result, .5f, .5f);
    result = CGAffineTransformRotate(result, self.rotation * M_PI / 180);
    result = CGAffineTransformTranslate(result, -.5f, -.5f);
    result = CGAffineTransformScale(result, 1 / pdfRect.size.width, 1 / pdfRect.size.height);
    result = CGAffineTransformTranslate(result, 0, pdfRect.size.height);
    result = CGAffineTransformTranslate(result, -pdfRect.origin.x, pdfRect.origin.y);
    return result;
}

- (CGRect)viewRectFromPDFRect:(CGRect)rect pageRect:(CGRect)frame
{
    rect.origin.y = -(rect.origin.y + rect.size.height);
    rect = CGRectApplyAffineTransform(rect, [self pdfToViewTransformWithPageRect:frame]);
    return rect;
}

- (void)drawInContext:(CGContextRef)context pageRect:(CGRect)frame
{
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, CGContextGetClipBoundingBox(context));
    CGAffineTransform t = [self pdfToViewTransformWithPageRect:frame];
    CGContextConcatCTM(context, t);
    // space is flipped horizontally
    CGContextScaleCTM(context, 1, -1);
    CGContextDrawPDFPage(context, ref);
}

#if TARGET_OS_IPHONE
- (UIImage *)imageFromFrame:(CGRect)frame
{
    UIGraphicsBeginImageContext(frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    [self drawInContext:context pageRect:frame];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();    
    return result;
}
#endif

- (CGRect)pageWithin:(CGSize)maxSize
{
    CGRect r = [self viewRectFromPDFRect:CGRectMake(0, 0, 1, 1) pageRect:CGRectMake(0, 0, 1, 1)];
    if (CGRectIsEmpty(r)) {
        return CGRectZero;
    }
    CGFloat widthScale = maxSize.width / r.size.height;
    CGFloat heightScale = maxSize.height / r.size.width;
    if (widthScale < heightScale) {
        CGFloat height = widthScale * r.size.width;
        return CGRectMake(0, (maxSize.height - height) / 2, maxSize.width, height);
    } else {
        CGFloat width = heightScale * r.size.height;
        return CGRectMake((maxSize.width - width) / 2, 0, width, maxSize.height);
    }
}


#pragma mark - Annotations

- (NSArray *)extractAnnotations
{
    CGPDFDictionaryRef dict = CGPDFPageGetDictionary(ref);
    CGPDFArrayRef array = NULL;
    if (!CGPDFDictionaryGetArray(dict, "Annots", &array)) {
        return nil;
    }
    NSInteger count = CGPDFArrayGetCount(array);
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        NWPDFAnnotation *annotation = [[NWPDFAnnotation alloc] initWithPage:self index:i];
        [result addObject:annotation];
    }
    return result;
}


#pragma mark - Logging

- (NSString *)about
{
    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"<%@>", NSStringFromClass([self class])];
    [result appendFormat:@"\nindex    : %u", (int)self.index];
    [result appendFormat:@"\nlabel    : %@", self.label];
    [result appendFormat:@"\nrotation : %u", (int)self.rotation];
    [result appendFormat:@"\npageRatio: %f", self.pageRatio];
    return result;
}

@end
