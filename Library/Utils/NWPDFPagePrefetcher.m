//
//  NWPDFPagePrefetcher.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFPagePrefetcher.h"
#import "NWPDFCache.h"
#import "NWPDFDocument.h"
#import "NWPDFPage.h"
#import "NWLCore.h"


@implementation NWPDFPagePrefetcher {
    NSUInteger lastIndex;
    NSMutableArray *tasks;
    dispatch_queue_t serial;
}

@synthesize cache, size;

- (id)init
{
    NWLogWarn(@"init not supported");
    return nil;
}

- (id)initWithCache:(NWPDFCache *)_cache size:(CGSize)_size
{
    self = [super init];
    if (self) {
        cache = _cache;
        size = _size;
        tasks = [[NSMutableArray alloc] init];
        serial = dispatch_queue_create("NWPDFPrefetcher", DISPATCH_QUEUE_SERIAL);
        lastIndex = -1;
    }
    return self;
}

- (void)dealloc
{
    //dispatch_release(serial);
    serial = NULL;
}

- (void)cancelAll
{
    for (NWPDFCacheTask *task in tasks) {
        [task cancel];
    }
    [tasks removeAllObjects];
}

- (void)prefetchFor:(NSUInteger)index
{
    dispatch_async(serial, ^{
        NWLogDbug(@"Prefetching for page: %i (queued:%u) (cached:%@)", (int)index, (int)cache.taskCount, cache.pagesString);
        NSInteger diff = (NSInteger)index - (NSInteger)lastIndex;
        if (diff == -1 || diff == 1) {
            [self cancelAll];
            NSMutableArray *sequence = [NSMutableArray array];
            [sequence addObject:[NSNumber numberWithInteger:index + diff]];
            [sequence addObject:[NSNumber numberWithInteger:index + diff * 2]];
            [sequence addObject:[NSNumber numberWithInteger:index - diff]];
            [sequence addObject:[NSNumber numberWithInteger:index + diff * 3]];
            [sequence addObject:[NSNumber numberWithInteger:index]];
            [self tryEnsure:sequence];
        } else if (diff != 0) {
            [self cancelAll];
            NSInteger dir = diff < 0 ? -1 : 1;
            NSMutableArray *sequence = [NSMutableArray array];
            [sequence addObject:[NSNumber numberWithInteger:index + dir]];
            [sequence addObject:[NSNumber numberWithInteger:index - dir]];
            [sequence addObject:[NSNumber numberWithInteger:index + dir * 2]];
            [sequence addObject:[NSNumber numberWithInteger:index - dir * 2]];
            [sequence addObject:[NSNumber numberWithInteger:index]];
            [self tryEnsure:sequence];
        }
        lastIndex = index;
    });
}

- (void)tryEnsure:(NSArray *)indices
{
//    NWLogWarnIfNot(dispatch_get_current_queue() == serial, @"Expected serial queue");

    NSUInteger pageCount = cache.document.pageCount;

    // add tasks as long a memory is available
    unsigned long long available = cache.memoryCacheSizeMax;
    for (NSNumber *n in indices) {
        NSInteger index = n.integerValue;
        if (index >= 0 && index < pageCount) {
            CGSize s = [cache sizeForPage:index within:size];
            unsigned long long area = s.width * s.height;
            if (available > area) {
                [tasks addObject:[cache imageForPage:index within:size priority:kNWPDFCachePriorityLow block:nil]];
                available -= area;
            } else {
                NWLogDbug(@"Skipping page %i (%f, %f), not enough cache memory", (int)index, size.width, size.height);
            }
        }
    }
}

@end
