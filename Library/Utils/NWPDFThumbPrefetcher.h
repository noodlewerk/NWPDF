//
//  NWPDFThumbPrefetcher.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFCache.h"

@class NWPDFDocument, NWPDFCache, NWPDFCacheTask;

@interface NWPDFThumbPrefetcher : NSObject

@property (nonatomic, readonly) NWPDFCache *cache;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, assign) NSUInteger span;

- (id)initWithCache:(NWPDFCache *)cache size:(CGSize)size count:(NSUInteger)count;

- (void)prefetchFor:(NSUInteger)index;
- (void)prefetchForRange:(NSRange)range;
- (void)thumbForIndex:(NSUInteger)index block:(void(^)(NWImage *))block;
- (NSUInteger)pageForIndex:(NSUInteger)index;

@end
