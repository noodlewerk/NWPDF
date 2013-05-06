//
//  NWPDFAnnotation.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class NWPDFPage;

@interface NWPDFAnnotation : NSObject

@property (nonatomic, readonly) CGPDFDictionaryRef ref;
@property (nonatomic, readonly) NWPDFPage *page;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly) BOOL hasAppearanceStream;
@property (nonatomic, readonly) NSInteger flags;
@property (nonatomic, readonly) NSUInteger index;
           
- (id)initWithPage:(NWPDFPage *)page index:(NSUInteger)index;
- (void)drawInContext:(CGContextRef)ctx;

@end
