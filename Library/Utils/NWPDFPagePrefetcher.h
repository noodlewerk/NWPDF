//
//  NWPDFPagePrefetcher.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class NWPDFDocument, NWPDFCache;

@interface NWPDFPagePrefetcher : NSObject

@property (nonatomic, readonly) NWPDFCache *cache;
@property (nonatomic, assign) CGSize size;

- (id)initWithCache:(NWPDFCache *)cache size:(CGSize)size;

- (void)prefetchFor:(NSUInteger)index;

@end
