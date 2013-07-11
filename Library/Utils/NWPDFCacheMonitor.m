//
//  NWPDFCacheMonitor.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFCacheMonitor.h"
#import "NWPDFCache.h"
#import "NWPDFCommon.h"
#import "NWLCore.h"


@interface NWPDFCacheMonitorLogDelegate : NSObject <NWPDFCacheMonitorEventDelegate>
@end


@implementation NWPDFCacheMonitor {
    dispatch_queue_t serialQueue;
    dispatch_queue_t delegateQueue;
        
    // atomic counter
    NSMutableDictionary *atomicCounters;
}

@synthesize delegate;
@synthesize startCount, hitCount, drawnCount, failCount, cancelCount;
@synthesize cacheSize, trimSize, cacheCount, queueSize;
@synthesize lastQueueTime, lastRenderTime, lastStoreTime, lastTotalTime;

#pragma mark - Object lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        serialQueue = dispatch_queue_create("NWPDFCacheMonitor.serialQueue", DISPATCH_QUEUE_SERIAL);
        atomicCounters = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    //dispatch_release(serialQueue);
    serialQueue = NULL;
    //dispatch_release(delegateQueue);
    delegateQueue = NULL;
}


#pragma mark - Updating

- (void)setUpdateToLog
{
    self.delegate = [[NWPDFCacheMonitorLogDelegate alloc] init];
}

- (void)setDelegate:(id<NWPDFCacheMonitorEventDelegate>)_delegate
{
//    delegateQueue = dispatch_get_current_queue();
//    if (!delegateQueue) {
    delegateQueue = dispatch_get_main_queue();
//    }
    //dispatch_retain(delegateQueue);
    delegate = _delegate;
}

- (void)updateWithEvent:(NWPDFCacheEventType)event
{
    if (delegateQueue) {
        dispatch_async(delegateQueue, ^{
            [delegate monitor:self hadEvent:event];
        });
    }
}


#pragma mark - Start / End registration

- (void)registerEventStart:(NWPDFCacheKey *)key
{
    dispatch_async(serialQueue, ^{
        startCount++;
        lastTotalTime = 0;
        lastQueueTime = 0;
        lastRenderTime = 0;
        lastStoreTime = 0;
        [self updateWithEvent:kNWPDFMonitorEventStart];
    });
}

- (void)registerEventHit:(NWPDFCacheKey *)key time:(NSTimeInterval)time
{
    dispatch_async(serialQueue, ^{
        hitCount++;
        lastTotalTime = time;
        [self updateWithEvent:kNWPDFMonitorEventHit];
    });
}

- (void)registerEventDrawn:(NWPDFCacheKey *)key time:(NSTimeInterval)time
{
    dispatch_async(serialQueue, ^{
        drawnCount++;
        lastTotalTime = time;
        [self updateWithEvent:kNWPDFMonitorEventDrawn];
    });
}
- (void)registerEventFail:(NWPDFCacheKey *)key time:(NSTimeInterval)time
{
    dispatch_async(serialQueue, ^{
        failCount++;
        lastTotalTime = time;
        [self updateWithEvent:kNWPDFMonitorEventFail];
    });
}

- (void)registerEventCancel:(NWPDFCacheKey *)key time:(NSTimeInterval)time
{
    dispatch_async(serialQueue, ^{
        cancelCount++;
        lastTotalTime = time;
        [self updateWithEvent:kNWPDFMonitorEventCancel];
    });
}


#pragma mark - Cache event registration

- (void)registerCacheStore:(NWPDFCacheKey *)key
{
    dispatch_async(serialQueue, ^{
        cacheCount++;
        cacheSize += key.area;
        [self updateWithEvent:kNWPDFMonitorCacheStore];
    });
}

- (void)registerCacheDuplicate:(NWPDFCacheKey *)key
{
    dispatch_async(serialQueue, ^{
        [self updateWithEvent:kNWPDFMonitorCacheDuplicate];
    });
}

- (void)registerCacheFull:(NWPDFCacheKey *)key
{
    dispatch_async(serialQueue, ^{
        [self updateWithEvent:kNWPDFMonitorCacheFull];
    });
}

- (void)registerCacheTrim:(NWPDFCacheKey *)key area:(NSUInteger)area
{
    dispatch_async(serialQueue, ^{
        cacheCount--;
        cacheSize -= area;
        trimSize += area;
        [self updateWithEvent:kNWPDFMonitorCacheTrim];
    });
}

- (void)registerCacheClear
{
    dispatch_async(serialQueue, ^{
        cacheCount = 0;
        trimSize += cacheSize;
        cacheSize = 0;
        [self updateWithEvent:kNWPDFMonitorCacheClear];
    });
}


#pragma mark - Timing event registration

- (void)registerTimeQueue:(NWPDFCacheKey *)key time:(NSTimeInterval)time
{
    dispatch_async(serialQueue, ^{
        lastQueueTime = time;
        [self updateWithEvent:kNWPDFMonitorTimeQueue];
    });
}

- (void)registerTimeRender:(NWPDFCacheKey *)key time:(NSTimeInterval)time
{
    dispatch_async(serialQueue, ^{
        lastRenderTime = time;
        [self updateWithEvent:kNWPDFMonitorTimeRender];
    });
}

- (void)registerTimeStore:(NWPDFCacheKey *)key time:(NSTimeInterval)time
{
    dispatch_async(serialQueue, ^{
        lastStoreTime = time;
        [self updateWithEvent:kNWPDFMonitorCacheTrim];
    });
}


#pragma mark - Atomic counters

- (void)atomicAdd:(NSString *)key value:(long long)value
{
    dispatch_async(serialQueue, ^{
        long long newValue = [[atomicCounters objectForKey:key] longLongValue] + value;
        [atomicCounters setObject:[NSNumber numberWithLongLong:newValue] forKey:key];
    });
}

- (long long)atomicValue:(NSString *)key
{
    __block long long result = 0;
    dispatch_sync(serialQueue, ^{
        result = [[atomicCounters objectForKey:key] longLongValue];
    });
    return result;
}

#define RB(a) [self.class stringFromSize:a]
+ (NSString *)stringFromSize:(long long)value
{
    if (value > -1000 && value < 1000) {
        return [NSString stringWithFormat:@"%lli", value];
    }
    if (value > -1000000 && value < 1000000) {
        return [NSString stringWithFormat:@"%lliK", value / 1000];
    }
    if (value > -1000000000 && value < 1000000000) {
        return [NSString stringWithFormat:@"%lliM", value / 1000000];
    }
    if (value > -1000000000000 && value < 1000000000000) {
        return [NSString stringWithFormat:@"%lliG", value / 1000000000];
    }
    return [NSString stringWithFormat:@"%lliT", value / 1000000000000];
}

- (void)atomicCheck:(NSString *)key threshold:(long long)threshold
{
    long long value = [self atomicValue:key];
    if (value >= threshold) {
        NWLogWarn(@"CHECK %@:%@ >= %@", key, RB(value), RB(threshold));
    }
}

- (void)atomicReset:(NSString *)key
{
    dispatch_async(serialQueue, ^{
        [atomicCounters removeObjectForKey:key];
    });
}


#pragma mark - Logging

+ (NSString *)stringWithType:(NWPDFCacheEventType)type
{
    switch (type) {
        case kNWPDFMonitorEventStart     : return @"strt";
        case kNWPDFMonitorEventDrawn     : return @"drwn";
        case kNWPDFMonitorEventHit       : return @"hit ";
        case kNWPDFMonitorEventFail      : return @"fail";
        case kNWPDFMonitorEventCancel    : return @"cncl";
        case kNWPDFMonitorCacheStore     : return @"stor";
        case kNWPDFMonitorCacheTrim      : return @"trim";
        case kNWPDFMonitorCacheDuplicate : return @"DUP!";
        case kNWPDFMonitorCacheFull      : return @"FUL!";
        case kNWPDFMonitorCacheClear     : return @"CLR!";
        case kNWPDFMonitorTimeQueue      : return @"tmqu";
        case kNWPDFMonitorTimeRender     : return @"tmrn";
        case kNWPDFMonitorTimeTrim       : return @"tmtr";
    }
}

- (NSString *)legenda
{
    return [NSString stringWithFormat:@"(s)tart/(h)it/(d)raw/(f)ail/(c)ancel-count  (q)ueue/(r)ender/(s)tore/(d)one-time  (#)caches/(c)ache/(t)rim-size"];  
}

#define MS(a) (int)(a*1000)
- (NSString *)about
{
    return [NSString stringWithFormat:@"  s/h/d/f/c:%3u/%2u/%2u/%2u/%2u    q/r/s/d:%3u/%3u/%3u/%3u    #/c/t:%2u/%@/%@", 
            (int)startCount, (int)hitCount, (int)drawnCount, (int)failCount, (int)cancelCount,
            MS(lastQueueTime), MS(lastRenderTime), MS(lastStoreTime), MS(lastTotalTime), 
            (int)cacheCount, RB(cacheSize), RB(trimSize)];
}

@end


@implementation NWPDFCacheMonitorLogDelegate

- (void)monitor:(NWPDFCacheMonitor *)monitor hadEvent:(NWPDFCacheEventType)event
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NWLogDbug(@"%@", monitor.legenda);
    });
    switch (event) {
        case kNWPDFMonitorEventHit:
        case kNWPDFMonitorEventDrawn:
        case kNWPDFMonitorEventFail:
        case kNWPDFMonitorEventCancel:
        case kNWPDFMonitorCacheDuplicate:
        case kNWPDFMonitorCacheFull:
        case kNWPDFMonitorCacheClear:
            break;
        default:
            return;
    }
    NWLogDbug(@"(%@) %@", [NWPDFCacheMonitor stringWithType:event], monitor.about);
}

@end
