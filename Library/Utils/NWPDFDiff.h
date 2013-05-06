//
//  NWPDFDiff.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class NWPDFPage;

@interface NWPDFDiff : NSObject

@property (nonatomic, strong, readonly) NWPDFPage *a;
@property (nonatomic, strong, readonly) NWPDFPage *b;

- (id)initWithPageA:(NWPDFPage *)a b:(NWPDFPage *)b;

// Compares page, using raster and vector diffing, returning a covering rectangle
- (CGRect)diff;

@end
