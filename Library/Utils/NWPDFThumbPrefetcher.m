//
//  NWPDFThumbPrefetcher.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFThumbPrefetcher.h"
#import "NWPDFCache.h"
#import "NWPDFDocument.h"
#import "NWPDFPage.h"
#import <NWLogging/NWLCore.h>


@implementation NWPDFThumbPrefetcher {
    dispatch_queue_t serial;
}

@synthesize cache, size, count, span;

- (id)initWithCache:(NWPDFCache *)_cache size:(CGSize)_size count:(NSUInteger)_count
{
    self = [super init];
    if (self) {
        size = _size;
        count = _count;
        cache = _cache;
        span = 100;
        serial = dispatch_queue_create("NWPDFPrefetcher", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc
{
    //dispatch_release(serial);
    serial = NULL;
}

- (void)prefetchForRange:(NSRange)range
{
    dispatch_async(serial, ^{
        for (NSUInteger i = range.location; i < range.location + range.length; i++) {
            [cache imageForPage:i within:size priority:kNWPDFCachePriorityBackground block:nil];
        }
    });
}

- (void)prefetchFor:(NSUInteger)index
{
    dispatch_async(serial, ^{
        NSUInteger s = span;
        // should not prefetch beyond document
        NSUInteger pageCount = cache.document.pageCount;
        s = MIN(s, pageCount);
        // should not prefetch more than memory available
        NSUInteger spanWithSizeMax = cache.memoryCacheSizeMax / size.width / size.height;
        s = MIN(s, spanWithSizeMax);
        
        NSUInteger min = index - s/2, sup = index + s/2;
        if (index < s/2) {
            min = 0;
            sup = s;
        } else if (index + s/2 > pageCount) {
            min = pageCount - s;
            sup = pageCount;
        }
        for (NSUInteger i = min; i < sup; i++) {
            [cache imageForPage:i within:size priority:kNWPDFCachePriorityBackground block:nil];
        }
        NWLogDbug(@"Prefetching for page %i #:%u (queued:%u) (cached:%@)", (int)index, (int)(sup - min), (int)cache.taskCount, cache.pagesString);
    });
}

- (NSUInteger)pageForIndex:(NSUInteger)index
{
    NSUInteger pageCount = cache.document.pageCount;
    NSUInteger result = index * pageCount / count;
    if (result < pageCount) {
        return result;
    }
    return 0;
}

- (void)thumbForIndex:(NSUInteger)index block:(void(^)(NWImage *))block
{
    NWLogWarnIfNot(index < count, @"Expecting index withing range: %i %i", (int)index, (int)count);
    dispatch_async(serial, ^{
        NSUInteger page = [self pageForIndex:index];
        [cache imageForPage:page within:size priority:kNWPDFCachePriorityBackground block:block];
    });
}

@end
