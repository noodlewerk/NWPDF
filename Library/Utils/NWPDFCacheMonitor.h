//
//  NWPDFCacheMonitor.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NWPDFCacheKey, NWPDFCacheMonitor;
@protocol NWPDFCacheMonitorEventDelegate;


typedef enum {
    // marks the beginning or end of load
    kNWPDFMonitorEventStart,
    kNWPDFMonitorEventHit,
    kNWPDFMonitorEventDrawn,
    kNWPDFMonitorEventFail,
    kNWPDFMonitorEventCancel,
    // marks operations on cache
    kNWPDFMonitorCacheStore,
    kNWPDFMonitorCacheTrim,
    kNWPDFMonitorCacheDuplicate,
    kNWPDFMonitorCacheFull,
    kNWPDFMonitorCacheClear,
    // marks events in time
    kNWPDFMonitorTimeQueue,
    kNWPDFMonitorTimeRender,
    kNWPDFMonitorTimeTrim,
} NWPDFCacheEventType;


#ifdef DEBUG

#define MONITOR_DECLARE() NWPDFCacheMonitor *monitor
#define MONITOR_INIT() {monitor = [[NWPDFCacheMonitor alloc] init];[monitor setUpdateToLog];}

#define MONITOR_EVENT_START(__key) [monitor registerEventStart:(__key)]
#define MONITOR_EVENT_HIT(__key, __time) [monitor registerEventHit:(__key) time:(__time)]
#define MONITOR_EVENT_DRAWN(__key,__time) [monitor registerEventDrawn:(__key) time:(__time)]
#define MONITOR_EVENT_FAIL(__key,__time) [monitor registerEventFail:(__key) time:(__time)]
#define MONITOR_EVENT_CANCEL(__key,__time) [monitor registerEventCancel:(__key) time:(__time)]

#define MONITOR_CACHE_STORE(__key) [monitor registerCacheStore:(__key)]
#define MONITOR_CACHE_DUPLICATE(__key) [monitor registerCacheDuplicate:(__key)]
#define MONITOR_CACHE_FULL(__key) [monitor registerCacheFull:(__key)]
#define MONITOR_CACHE_TRIM(__key,__area) [monitor registerCacheTrim:(__key) area:(__area)]
#define MONITOR_CACHE_CLEAR() [monitor registerCacheClear]

#define MONITOR_TIME_QUEUE(__key, __time) [monitor registerTimeQueue:(__key) time:(__time)]
#define MONITOR_TIME_RENDER(__key, __time) [monitor registerTimeRender:(__key) time:(__time)]
#define MONITOR_TIME_STORE(__key, __time) [monitor registerTimeStore:(__key) time:(__time)]

#define MONITOR_ATOMIC_INC(__key) [monitor atomicAdd:(__key) value:1]
#define MONITOR_ATOMIC_DEC(__key) [monitor atomicAdd:(__key) value:-1]
#define MONITOR_ATOMIC_ADD(__key,__value) [monitor atomicAdd:(__key) value:(__value)]
#define MONITOR_ATOMIC_SUB(__key,__value) [monitor atomicAdd:(__key) value:-(NSInteger)(__value)]
#define MONITOR_ATOMIC_CHECK(__key,__threshold) [monitor atomicCheck:(__key) threshold:(__threshold)]
#define MONITOR_ATOMIC_RESET(__key) [monitor atomicReset:(__key)]

#else

#define MONITOR_DECLARE()
#define MONITOR_INIT()

#define MONITOR_EVENT_START(__key)
#define MONITOR_EVENT_HIT(__key, __time)
#define MONITOR_EVENT_DRAWN(__key,__time)
#define MONITOR_EVENT_FAIL(__key,__time)
#define MONITOR_EVENT_CANCEL(__key,__time)

#define MONITOR_CACHE_STORE(__key)
#define MONITOR_CACHE_DUPLICATE(__key)
#define MONITOR_CACHE_FULL(__key)
#define MONITOR_CACHE_TRIM(__key,__trimmee)
#define MONITOR_CACHE_CLEAR()

#define MONITOR_TIME_QUEUE(__key, __time)
#define MONITOR_TIME_RENDER(__key, __time)
#define MONITOR_TIME_STORE(__key, __time)

#define MONITOR_ATOMIC_INC(__key)
#define MONITOR_ATOMIC_DEC(__key)
#define MONITOR_ATOMIC_ADD(__key,__value)
#define MONITOR_ATOMIC_SUB(__key,__value)
#define MONITOR_ATOMIC_CHECK(__key,__threshold)
#define MONITOR_ATOMIC_RESET(__key)

#endif

@interface NWPDFCacheMonitor : NSObject

@property (nonatomic, strong) id<NWPDFCacheMonitorEventDelegate> delegate;

// counters
@property (nonatomic, readonly) NSUInteger startCount;
@property (nonatomic, readonly) NSUInteger hitCount;
@property (nonatomic, readonly) NSUInteger drawnCount;
@property (nonatomic, readonly) NSUInteger failCount;
@property (nonatomic, readonly) NSUInteger cancelCount;

// cache
@property (nonatomic, readonly) unsigned long long cacheSize;
@property (nonatomic, readonly) unsigned long long trimSize;
@property (nonatomic, readonly) NSUInteger cacheCount;
@property (nonatomic, readonly) NSUInteger queueSize;

// last timers
@property (nonatomic, readonly) NSTimeInterval lastQueueTime;
@property (nonatomic, readonly) NSTimeInterval lastRenderTime;
@property (nonatomic, readonly) NSTimeInterval lastStoreTime;
@property (nonatomic, readonly) NSTimeInterval lastTotalTime;

- (void)setUpdateToLog;

- (void)registerEventStart:(NWPDFCacheKey *)key;
- (void)registerEventHit:(NWPDFCacheKey *)key time:(NSTimeInterval)time;
- (void)registerEventDrawn:(NWPDFCacheKey *)key time:(NSTimeInterval)time;
- (void)registerEventFail:(NWPDFCacheKey *)key time:(NSTimeInterval)time;
- (void)registerEventCancel:(NWPDFCacheKey *)key time:(NSTimeInterval)time;

- (void)registerCacheStore:(NWPDFCacheKey *)key;
- (void)registerCacheDuplicate:(NWPDFCacheKey *)key;
- (void)registerCacheFull:(NWPDFCacheKey *)key;
- (void)registerCacheTrim:(NWPDFCacheKey *)key area:(NSUInteger)area;
- (void)registerCacheClear;

- (void)registerTimeQueue:(NWPDFCacheKey *)key time:(NSTimeInterval)time;
- (void)registerTimeRender:(NWPDFCacheKey *)key time:(NSTimeInterval)time;
- (void)registerTimeStore:(NWPDFCacheKey *)key time:(NSTimeInterval)time;

- (void)atomicAdd:(NSString *)key value:(long long)value;
- (void)atomicCheck:(NSString *)key threshold:(long long)threshold;
- (void)atomicReset:(NSString *)key;

- (NSString *)legenda;
- (NSString *)about;
+ (NSString *)stringWithType:(NWPDFCacheEventType)type;
+ (NSString *)stringFromSize:(long long)value;

@end



@protocol NWPDFCacheMonitorEventDelegate <NSObject>

- (void)monitor:(NWPDFCacheMonitor *)monitor hadEvent:(NWPDFCacheEventType)event;

@end
