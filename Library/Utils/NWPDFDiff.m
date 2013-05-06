//
//  NWPDFDiff.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFDiff.h"
#import "NWPDFPage.h"
#import "NWPDFNode.h"
#import "NWPDFCommon.h"
#import <NWLogging/NWLCore.h>


@implementation NWPDFDiff

@synthesize a, b;


#pragma mark - Object lifecycle

- (id)initWithPageA:(NWPDFPage *)_a b:(NWPDFPage *)_b
{
    self = [super init];
    if (self) {
        a = _a;
        b = _b;
    }
    return self;
}


#pragma mark - Diffing

- (CGRect)rasterDiffWithSize:(CGSize)maxSize
{
    // no other page, return all different
    // this page too small to compare
    CGRect frame = [a pageWithin:maxSize];
    if (CGRectIsEmpty(frame)) {
        // unable to compare in this space
        return a.pdfRect;
    }
    CGImageRef aImage = NULL;//[self thumbImageWithPage:frame].CGImage;
    CGImageRef bImage = NULL;//[page thumbImageWithPage:frame].CGImage;
    CFDataRef aData = CGDataProviderCopyData(CGImageGetDataProvider(aImage));
    CFDataRef bData = CGDataProviderCopyData(CGImageGetDataProvider(bImage));
    size_t aWidth = CGImageGetWidth(aImage);
    size_t bWidth = CGImageGetWidth(bImage);
    size_t aHeight = CGImageGetHeight(aImage);
    size_t bHeight = CGImageGetHeight(bImage);
    size_t aSize = CFDataGetLength(aData);
    size_t bSize = CFDataGetLength(bData);
    if (aWidth != bWidth || aHeight != bHeight || aSize != bSize) {
        // image sizes differ, unable to compare (TODO)
        CFRelease(aData);
        CFRelease(bData);
        return a.pdfRect;
    }
    size_t bytesRow = CGImageGetBytesPerRow(aImage);
    size_t bitsPixel = CGImageGetBitsPerPixel(aImage);
    NSUInteger xMin = aWidth;
    NSUInteger xMax = 0;
    NSUInteger yMin = aHeight;
    NSUInteger yMax = 0;
    const UInt8 *aIt = CFDataGetBytePtr(aData);
    const UInt8 *bIt = CFDataGetBytePtr(bData);
    // TODO: lots of room for improvement of the traversal path
    for (size_t y = 0; y < aHeight; y++) {
        for (size_t bb = 0; bb < bytesRow; bb++) {
            if (*aIt != *bIt) {
                size_t x = bb * 8 / bitsPixel;
                if (xMin > x) xMin = x;
                if (xMax < x) xMax = x;
                if (yMin > y) yMin = y;
                if (yMax < y) yMax = y;
            }
            aIt++;
            bIt++;
        }
    }
    CFRelease(aData);
    CFRelease(bData);
    if (xMin > xMax) {
        // no difference found
        return CGRectZero;
    }
    // scale back to standard pdf points
    // TODO: use pdfToViewTransformWithPage instead of manual transforms
    CGFloat scaleX = a.pdfRect.size.width / frame.size.width;
    CGFloat scaleY = a.pdfRect.size.height / frame.size.height;
    CGRect result = CGRectMake(xMin * scaleX, yMin * scaleY, (xMax - xMin + 1) * scaleX, (yMax - yMin + 1) * scaleY);
    // transform to pdf coordinates
    result.origin.y = a.pdfRect.size.height - result.origin.y - result.size.height;
    return CGRectIntersection(a.pdfRect, result);
}

- (BOOL)vectorDiffWithDepth:(NSUInteger)maxDepth
{
    // no other page, return all different
    NWPDFPageNode *aDict = [[NWPDFPageNode alloc] initWithKey:nil uid:(NSUInteger)a.ref];
    NWPDFPageNode *bDict = [[NWPDFPageNode alloc] initWithKey:nil uid:(NSUInteger)b.ref];
    aDict.page = a.ref;
    bDict.page = b.ref;
    return [NWPDFNode isEqual:aDict to:bDict depth:maxDepth] != kNWPDFNodeCompareEqual;
}

- (CGRect)diff
{
    CGSize defaultSize = CGSizeMake(64, 64);
    CGRect r = [self rasterDiffWithSize:defaultSize];
    if (!CGRectIsEmpty(r)) {
        return r;
    }
    if ([self vectorDiffWithDepth:100]) {
        NWLog(@"Page was changed invisibly");
        return a.pdfRect;
    }
    return CGRectZero;
}


@end
