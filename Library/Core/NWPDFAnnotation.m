//
//  NWPDFAnnotation.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFAnnotation.h"
#import "NWPDFPage.h"
#import "NWPDFCommon.h"


@implementation NWPDFAnnotation

@synthesize ref, page, index;


#pragma mark - Object lifecycle

- (id)initWithPage:(NWPDFPage *)_page index:(NSUInteger)_index
{
    self = [super init];
    if(self){
        page = _page;
        index = _index;
        CGPDFDictionaryRef dict = CGPDFPageGetDictionary(page.ref);
        CGPDFArrayRef array = NULL;
        if (CGPDFDictionaryGetArray(dict, "Annots", &array) && array) {
            CGPDFArrayGetDictionary(array, _index, &ref);
        }
    }
    return self;
}


#pragma mark - Basic properties

- (NSString *)type
{
    return [NWPDFCommon nameFromDictionary:ref key:"Subtype"];
}

- (CGRect)bounds
{
    CGPDFArrayRef array;
    if(!CGPDFDictionaryGetArray(ref, "Rect", &array)){
        return CGRectZero;
    }
    if(CGPDFArrayGetCount(array) != 4){
        return CGRectZero;
    }
    return [NWPDFCommon rectFrom:array];
} 

- (BOOL)hasAppearanceStream
{
    CGPDFDictionaryRef dict;
    return CGPDFDictionaryGetDictionary(ref, "AP", &dict);
}

- (NSInteger)flags
{
    return [NWPDFCommon integerFromDictionary:ref key:"F" defaultsTo:-1];
}

- (CGPDFDictionaryRef)ref
{
    return ref;
}


#pragma mark - Drawing

- (void)drawInContext:(CGContextRef)ctx
{          
    CGRect b = self.bounds;
    CGContextSetRGBFillColor(ctx, 0, 0, 1, .1);
    CGContextFillRect(ctx, b);
    CGContextSetRGBStrokeColor(ctx, 0, 0, 1, 1);
    CGContextStrokeRect(ctx, b);
}

@end
