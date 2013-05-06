//
//  NWPDFCache.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFCache.h"
#import "NWPDFCacheMonitor.h"
#import "NWPDFDocument.h"
#import "NWPDFPage.h"
#import <NWLogging/NWLCore.h>


@implementation NWPDFCacheKey

@synthesize index, width, height;

- (id)initWithIndex:(NSUInteger)_index width:(NSUInteger)_width height:(NSUInteger)_height
{
    self = [super init];
    if (self) {
        index = _index;
        width = _width;
        height = _height;
    }
    return self;
}

- (NSUInteger)area
{
    return width * height;
}

@end



@interface NWPDFCacheTask () 
@property (atomic, assign) BOOL cancelled;
@property (atomic, readonly) NSTimeInterval time;
@property (atomic, readonly) NSTimeInterval diff;
@end

@implementation NWPDFCacheTask {
    NSTimeInterval start;
    NSTimeInterval last;
}
@synthesize cancelled;
- (id)init
{
    self = [super init];
    if (self) {
        start = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}
- (void)cancel
{
    self.cancelled = YES;
}
- (NSTimeInterval)time
{
    return [[NSDate date] timeIntervalSince1970] - start;
}
- (NSTimeInterval)diff
{
    NSTimeInterval l = last;
    last = self.time;
    return last - l;
}
@end



@interface NWPDFCacheEntry : NSObject
@property (nonatomic, strong) NWImage *image;
@property (nonatomic, assign) NSTimeInterval accessTime;
@end

@implementation NWPDFCacheEntry
@synthesize image, accessTime;
- (id)initWithImage:(NWImage *)_image
{
    self = [super init];
    if (self) {
        image = _image;
        accessTime = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}
- (void)hit
{
    accessTime = [[NSDate date] timeIntervalSince1970];
}
@end


@implementation NWPDFCache {
    // dictionary key => image data in memory
    NSMutableDictionary *store;
    dispatch_queue_t serial;
    NSOperationQueue *renderQueue;
    MONITOR_DECLARE();
}

@synthesize monitor, document, memoryCacheSize, memoryCacheSizeMax;


#pragma mark - Object lifecycle

- (id)init
{
    NWLogWarn(@"init not supported");
    return nil;
}

- (id)initWithDocument:(NWPDFDocument *)_document
{
    self = [super init];
    if (self) {
        document = _document;
        store = [[NSMutableDictionary alloc] init];
        serial = dispatch_queue_create("NWPDFCache.memoryCacheQueue", DISPATCH_QUEUE_SERIAL);
        renderQueue = [[NSOperationQueue alloc] init];
        renderQueue.maxConcurrentOperationCount = 1;
        memoryCacheSizeMax = 1000 * 1000; // 1 MB
        MONITOR_INIT();
    }
    return self;
}

- (void)dealloc
{
    store = nil;
    //dispatch_release(serial);
    serial = NULL;
}

+ (NSOperationQueuePriority)priorityWithPriority:(NWPDFCachePriorityType)priority
{
    switch (priority) {
        case kNWPDFCachePriorityNormal: return NSOperationQueuePriorityNormal;
        case kNWPDFCachePriorityLow: return NSOperationQueuePriorityLow;
        case kNWPDFCachePriorityBackground:
        default: return NSOperationQueuePriorityVeryLow;
    }
}

- (void)reduceCacheSizeWithFactor:(float)factor
{
    NWLogWarnIfNot(factor >= 0 && factor <= 1, @"Expecting factor 0..1, %f", factor);
    dispatch_sync(serial, ^{
        memoryCacheSizeMax *= (1 - factor);
        NWLogInfo(@"Reduce cache size to %llu", memoryCacheSizeMax);
        [self trimMemoryCacheForKey:nil];
    });
}


#pragma mark - Rendering

- (NWImage *)renderImageForKey:(NWPDFCacheKey *)key
{
    NWLogWarnIfNot(key.area, @"Expecting positive size to render");
    NWPDFPage *page = [document pageAtIndex:key.index];
    CGRect frame = CGRectMake(0, 0, key.width, key.height);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, frame.size.width, frame.size.height, 8, frame.size.width * 4, space, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(space);
    [page drawInContext:context pageRect:frame];
    CGImageRef i = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
#if TARGET_OS_IPHONE
    NWImage *result = [[NWImage alloc] initWithCGImage:i];
#else
    NWImage *result = [[NWImage alloc] initWithCGImage:i size:frame.size];
#endif
    CGImageRelease(i);
    return result;
}

- (NWImage *)renderImageFromImage:(NWImage *)image
{
    CGRect frame = CGRectMake(0, 0, image.size.width, image.size.height);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, frame.size.width, frame.size.height, 8, frame.size.width * 4, space, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(space);
#if TARGET_OS_IPHONE
    CGImageRef ref = image.CGImage;
#else
    CGImageRef ref = [image CGImageForProposedRect:nil context:nil hints:nil];
#endif
    CGContextDrawImage(context, frame, ref);
    CGImageRef i = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
#if TARGET_OS_IPHONE
    NWImage *result = [[NWImage alloc] initWithCGImage:i];
#else
    NWImage *result = [[NWImage alloc] initWithCGImage:i size:frame.size];
#endif
    CGImageRelease(i);
    return result;
}


#pragma mark - Cache access

- (NWPDFCacheEntry *)entryForKey:(NWPDFCacheKey *)key
{
//    NWLogWarnIfNot(dispatch_get_current_queue() == serial, @"");
    NSDictionary *d = [store objectForKey:[NSNumber numberWithUnsignedInteger:key.index]];
    NWPDFCacheEntry *result = [d objectForKey:[NSNumber numberWithUnsignedInteger:key.area]];
    return result;
}

- (void)setEntry:(NWPDFCacheEntry *)entry forKey:(NWPDFCacheKey *)key
{
//    NWLogWarnIfNot(dispatch_get_current_queue() == serial, @"");
    NSMutableDictionary *d = [store objectForKey:[NSNumber numberWithUnsignedInteger:key.index]];
    if (!d) {
        d = [[NSMutableDictionary alloc] init];
        [store setObject:d forKey:[NSNumber numberWithUnsignedInteger:key.index]];
    }
    if (![d objectForKey:[NSNumber numberWithUnsignedInteger:key.area]]) {
        memoryCacheSize += key.area;
        MONITOR_CACHE_STORE(key);
        MONITOR_ATOMIC_ADD(NWPDFCachePixelsAllocatedKey,key.area);
    }
    [d setObject:entry forKey:[NSNumber numberWithUnsignedInteger:key.area]];
}

- (void)removeEntryForKey:(NWPDFCacheKey *)key
{
//    NWLogWarnIfNot(dispatch_get_current_queue() == serial, @"");
    NSMutableDictionary *d = [store objectForKey:[NSNumber numberWithUnsignedInteger:key.index]];
    if ([d objectForKey:[NSNumber numberWithUnsignedInteger:key.area]]) {
        memoryCacheSize -= key.area;
        MONITOR_CACHE_TRIM(key, key.area);
        MONITOR_ATOMIC_SUB(NWPDFCachePixelsAllocatedKey, key.area);
    }
    [d removeObjectForKey:[NSNumber numberWithUnsignedInteger:key.area]];
    if (!d.count) {
        [store removeObjectForKey:[NSNumber numberWithUnsignedInteger:key.index]];
    }
}

- (NWPDFCacheKey *)oldestEntry
{
//    NWLogWarnIfNot(dispatch_get_current_queue() == serial, @"");
    __block NWPDFCacheKey *result = nil;
    __block NSTimeInterval earliest = 0;
    [store enumerateKeysAndObjectsUsingBlock:^(NSNumber *index, NSDictionary *d, BOOL *stop) {
        [d enumerateKeysAndObjectsUsingBlock:^(NSNumber *area, NWPDFCacheEntry *entry, BOOL *stop) {
            if (!result || earliest > entry.accessTime) {
                earliest = entry.accessTime;
                NWLogWarnIfNot(entry.image.size.width * entry.image.size.height == area.unsignedIntegerValue, @"Incompatible area for image");
                result = [[NWPDFCacheKey alloc] initWithIndex:index.unsignedIntegerValue width:entry.image.size.width height:entry.image.size.height];
            }
        }];
    }];
    return result;
}

- (NWPDFCacheEntry *)largestEntryForIndex:(NSUInteger)index
{
//    NWLogWarnIfNot(dispatch_get_current_queue() == serial, @"");
    NWPDFCacheEntry *result = nil;
    NSDictionary *d = [store objectForKey:[NSNumber numberWithUnsignedInteger:index]];
    NSUInteger max = 0;
    for (NSNumber *area in d) {
        NWPDFCacheEntry *entry = [d objectForKey:area];
        if (entry && max < area.unsignedIntegerValue) {
            result = entry;
            max = area.unsignedIntegerValue;
        }
    }
    return result;
}

- (NSString *)storeToString
{
    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"{"];
    [store enumerateKeysAndObjectsUsingBlock:^(NSNumber *index, NSDictionary *d, BOOL *stop) {
        [result appendFormat:@"%@{", index];
        [d enumerateKeysAndObjectsUsingBlock:^(NSNumber *area, NWPDFCacheEntry *entry, BOOL *stop) {
            [result appendFormat:@"%@,", area];
        }];
        [result appendFormat:@"},"];
    }];
    [result appendFormat:@"}"];
    return result;
}

+ (NSString *)rangeStringWithIntegers:(NSArray *)integers
{
    if (integers.count) {
        NSArray *sorted = [integers sortedArrayUsingSelector:@selector(compare:)];
        NSUInteger last = [[sorted objectAtIndex:0] unsignedIntegerValue], begin = last;
        NSMutableString *result = [[NSMutableString alloc] initWithFormat:@"%u", (int)last];
        for (NSNumber *number in sorted) {
            NSUInteger i = number.unsignedIntegerValue;
            if (i > last + 1) {
                if (begin == last) {
                    [result appendFormat:@",%u", (int)i];
                } else {
                    [result appendFormat:@"-%u,%u", (int)last, (int)i];
                }
                begin = i;
            }
            last = i;
        }
        if (begin != [sorted.lastObject unsignedIntegerValue]) {
            [result appendFormat:@"-%u", (int)last];
        }
        return result;
    }
    return @"";
}

- (NSString *)pagesString
{
    __block NSString *result = nil;
    dispatch_sync(serial, ^{
        result = [self.class rangeStringWithIntegers:store.allKeys];
    });
    return result;
}

#pragma mark - Memory cache scheduling

static NSString * const NWPDFCachePixelsAllocatedKey = @"pixels-allocated";


// trims the cache so it can hold a given image size
- (BOOL)trimMemoryCacheForKey:(NWPDFCacheKey *)key
{
//    NWLogWarnIfNot(dispatch_get_current_queue() == serial, @"");
    
    // TODO: this looping is far from optimal, maybe keep a sorted array around?
    NSUInteger area = key.area;
    while (memoryCacheSize + area > memoryCacheSizeMax) {
        NWPDFCacheKey *k = [self oldestEntry];
        if (!k) break;
        [self removeEntryForKey:k];
    }
    
    BOOL result = memoryCacheSize + area <= memoryCacheSizeMax;
    return result;
}

// calls trimming and caches a rendered image
- (void)storeForKey:(NWPDFCacheKey *)key image:(NWImage *)image
{
//    NWLogWarnIfNot(dispatch_get_current_queue() == serial, @"");

    if (![self entryForKey:key]) {
        // make room in the cache and store the image
        if ([self trimMemoryCacheForKey:key]) {
            NWPDFCacheEntry *entry = [[NWPDFCacheEntry alloc] initWithImage:image];
            [self setEntry:entry forKey:key];
        } else {
            // not enough space to store image, so pixels are freed
            MONITOR_CACHE_FULL(key);
        }
    } else {
        // image already there, so pixels are freed
        MONITOR_CACHE_DUPLICATE(key);
    }
}

// renders image and calls for caching
- (NWImage *)renderForKey:(NWPDFCacheKey *)key task:(NWPDFCacheTask *)task
{
    MONITOR_TIME_QUEUE(key, task.diff);
    // we're going to draw, so pixels are allocated
    MONITOR_ATOMIC_ADD(NWPDFCachePixelsAllocatedKey,key.area);
    MONITOR_ATOMIC_CHECK(NWPDFCachePixelsAllocatedKey,50 * 1000 * 1000);
    // perform render
    NWImage *result = [self renderImageForKey:key];
    MONITOR_TIME_RENDER(key, task.diff);
    if (result) {
        // store the new image
        dispatch_async(serial, ^{
            [self storeForKey:key image:result];
            MONITOR_TIME_STORE(key, task.diff);
        });
        if (task.cancelled) {MONITOR_EVENT_CANCEL(key, task.time); return nil;}
        MONITOR_EVENT_DRAWN(key, task.time);
    } else {
        MONITOR_EVENT_FAIL(key, task.time);
        // no image (probably no memory as well), so pixels are freed
    }
    MONITOR_ATOMIC_SUB(NWPDFCachePixelsAllocatedKey,key.area);
    return result;
}

- (BOOL)loadImageFromMemoryForKey:(NWPDFCacheKey *)key task:(NWPDFCacheTask *)task block:(void(^)(NWImage *))block
{
//    NWLogWarnIfNot(dispatch_get_current_queue() == serial, @"");

    if (task.cancelled) {MONITOR_EVENT_CANCEL(key, task.time); return YES;}
    NWPDFCacheEntry *entry = [self entryForKey:key];
    NWImage *image = entry.image;
    if (image) {
        NWLogWarnIfNot(image.size.width * image.size.height > 0, @"Expecting image to contain pixels");
        [entry hit];
        MONITOR_EVENT_HIT(key, task.time);
        // there already is an image, so return it
        if (block) block(image);
        return YES;
    }
    return NO;
}

// loads image, either from cache or by rendering it   
- (void)loadImageFromMemoryForKey:(NWPDFCacheKey *)key task:(NWPDFCacheTask *)task priority:(NWPDFCachePriorityType)priority block:(void(^)(NWImage *))block
{
    MONITOR_EVENT_START(key);
    dispatch_async(serial, ^{
        BOOL hit = [self loadImageFromMemoryForKey:key task:task block:block];
        if (!hit) {
            // no image, schedule the rendering of it
            NWLogDbug(@"queued: page %4u  %4u,%4u", (int)key.index, (int)key.width, (int)key.height);
//            MONITOR_ATOMIC_INC(NWPDFCacheRendersQueuedKey);
            NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
//                MONITOR_ATOMIC_DEC(NWPDFCacheRendersQueuedKey);
                __block BOOL hit = NO;
                dispatch_sync(serial, ^{
                    hit = [self loadImageFromMemoryForKey:key task:task block:block];
                });
                if (!hit) {
                    NWLogDbug(@"render: page%4u  %3u,%3u", (int)key.index, (int)key.width, (int)key.height);
                    NWImage *result = [self renderForKey:key task:task];
                    NWLogDbug(@"finish: page%4u  %3u,%3u", (int)key.index, (int)key.width, (int)key.height);
                    if (block) block(result);
                }
            }];
            operation.queuePriority = [self.class priorityWithPriority:priority];
            [renderQueue addOperation:operation];
        }
    });
}

// starting-point: prepares arguments and calls internal load method
- (NWPDFCacheTask *)imageForPage:(NSUInteger)index within:(CGSize)within priority:(NWPDFCachePriorityType)priority block:(void (^)(NWImage *))block
{
    NWLogWarnIfNot(index < document.pageCount, @"Index out of bounds: %u %u", (int)index, (int)document.pageCount);
    
    CGSize size = [self sizeForPage:index within:within];
    NWPDFCacheKey *key = [[NWPDFCacheKey alloc] initWithIndex:index width:size.width height:size.height];
    
    NWLogWarnIfNot(key.width < 10000, @"Large width: %u", (int)key.width);
    NWLogWarnIfNot(key.height < 10000, @"Large height: %u", (int)key.height);
    
    void(^b)(NWImage *) = nil;
    if (block) {
//        dispatch_queue_t queue = dispatch_get_current_queue();
//        if (!queue) {
//            queue = dispatch_get_main_queue();
//        }
//        dispatch_retain(queue);
        b = ^(NWImage *image){
            dispatch_async(dispatch_get_main_queue(), ^{
                block(image);
//                dispatch_release(queue);
            });
        };
    }
    
    NWPDFCacheTask *result = [[NWPDFCacheTask alloc] init];
    [self loadImageFromMemoryForKey:key task:result priority:priority block:b];
    return result;
}

- (CGSize)sizeForPage:(NSUInteger)index within:(CGSize)within
{
    NWPDFPage *page = [document pageAtIndex:index];
    CGSize s = [page pageWithin:within].size;
    NSUInteger width = roundf(s.width);
    NSUInteger height = roundf(s.height);
    CGSize result = CGSizeMake(width, height);
    return result;
}

// direct access cache without rendering
- (NWImage *)imageFromCacheForPage:(NSUInteger)index
{
    __block NWImage *result = nil;
    dispatch_sync(serial, ^{
        NWPDFCacheEntry *entry = [self largestEntryForIndex:index];
        [entry hit];
        result = entry.image;
    });
    NWLogWarnIfNot(!result || result.size.width * result.size.height > 0, @"Expecting image to contain pixels");
    return result;
}

- (void)clear
{
    dispatch_async(serial, ^{
        [store removeAllObjects];
        memoryCacheSize = 0;
        MONITOR_CACHE_CLEAR();
        MONITOR_ATOMIC_RESET(NWPDFCachePixelsAllocatedKey);
    });
}

- (NSUInteger)taskCount
{
    return renderQueue.operationCount;
}


#pragma mark - Cache I/O

- (void)writeToFolder:(NSString *)folder quality:(CGFloat)quality
{
    dispatch_async(serial, ^{
        NWLogDbug(@"Writing cache to: %@", folder);
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [store enumerateKeysAndObjectsUsingBlock:^(NSNumber *index, NSDictionary *d, BOOL *stop) {
            NSUInteger page = index.unsignedIntegerValue;
            [d enumerateKeysAndObjectsUsingBlock:^(NSNumber *area, NWPDFCacheEntry *entry, BOOL *stop) {
                NWImage *image = entry.image;
                if (image.size.width * image.size.height) {
                    NWLogDbug(@"Writing cache entry: %u %f,%f", (int)page, image.size.width, image.size.height);
                    [dict setObject:image forKey:[NSNumber numberWithUnsignedInteger:page]];
                }
            }];
        }];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            BOOL useJPEG = (quality >= 0 && quality <= 1);
            NSFileManager *manager = NSFileManager.defaultManager;
            NSError *error = nil;
            NSMutableSet *fileSet = [NSMutableSet setWithArray:[manager contentsOfDirectoryAtPath:folder error:&error]];
            NWLogWarnIfError(error);
            for (NSNumber *k in dict) {
                NSUInteger page = [k unsignedIntegerValue];
                NSString *name = [NSString stringWithFormat:@"%u.%@", (int)page, useJPEG ? @"jpg" : @"png"];
                if ([fileSet containsObject:name]) {
                    [fileSet removeObject:name];
                } else {
                    NSString *file = [folder stringByAppendingPathComponent:name];
                    NWImage *image = [dict objectForKey:k];
                    NSData *data = nil;
                    if (useJPEG) {
#if TARGET_OS_IPHONE
                        data = UIImageJPEGRepresentation(image, quality);
#else
                        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:[image CGImageForProposedRect:nil context:nil hints:nil]];
                        data = [rep representationUsingType:NSJPEGFileType properties:@{NSImageCompressionFactor:@(quality)}];
#endif
                    } else {
#if TARGET_OS_IPHONE
                        data = UIImagePNGRepresentation(image);
#else
                        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:[image CGImageForProposedRect:nil context:nil hints:nil]];
                        data = [rep representationUsingType:NSPNGFileType properties:nil];
#endif
                    }
                    if (data.length) {
                        NWLogDbug(@"Written cache image: %u %f,%f (%@)", (int)page, image.size.width, image.size.height, name);
                        [data writeToFile:file atomically:NO];
                    }
                }
            }
            for (NSString *name in fileSet) {
                NSString *file = [folder stringByAppendingPathComponent:name];
                NSError *error = nil;
               [manager removeItemAtPath:file error:&error];
                NWLogWarnIfError(error);
                NWLogDbug(@"Removing cache image: %@", name);
            }
        });
    });
}

- (void)readFromFolder:(NSString *)folder
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NWLogDbug(@"Reading cache from: %@", folder);
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        NSFileManager *manager = NSFileManager.defaultManager;
        NSError *error = nil;
        NSArray *files = [manager contentsOfDirectoryAtPath:folder error:&error];
        // TODO: http://stackoverflow.com/questions/1523793/get-directory-contents-in-date-modified-order
        NWLogWarnIfError(error);
        unsigned long long sum = 0;
        for (NSString *name in files) {
            NSUInteger page = name.stringByDeletingPathExtension.integerValue;
            NSString *file = [folder stringByAppendingPathComponent:name];
            NWImage *image = [[NWImage alloc] initWithContentsOfFile:file];
            if (image.size.width * image.size.height) {
                sum += image.size.width * image.size.height;
                if (sum > memoryCacheSizeMax) {
                    break;
                }
                NWLogDbug(@"Read cache image: %u %f,%f (%@)", (int)page, image.size.width, image.size.height, name);
                [dict setObject:image forKey:[NSNumber numberWithUnsignedInteger:page]];
            }
        }
        dispatch_async(serial, ^{
            for (NSNumber *k in dict) {
                NSUInteger page = [k unsignedIntegerValue];
                NWImage *image = [dict objectForKey:k];
                NWPDFCacheKey *key = [[NWPDFCacheKey alloc] initWithIndex:page width:image.size.width height:image.size.height];
                NWPDFCacheEntry *entry = [[NWPDFCacheEntry alloc] initWithImage:image];
                NWLogDbug(@"Read cache entry: %u %f,%f", (int)page, image.size.width, image.size.height);
                [self setEntry:entry forKey:key];
            }
        });
    });
}

- (NWImage *)readFromFolder:(NSString *)folder page:(NSUInteger)page
{
    NWLogDbug(@"Reading cached page %i from: %@", (int)page, folder);
    NSString *file = [folder stringByAppendingPathComponent:[NSString stringWithFormat:@"%u", (int)page]];
    NSFileManager *manager = NSFileManager.defaultManager;
    NWImage *image = nil;
    if ([manager fileExistsAtPath:[file stringByAppendingPathExtension:@"png"]]) {
        image = [[NWImage alloc] initWithContentsOfFile:[file stringByAppendingPathExtension:@"png"]];
    } else if ([manager fileExistsAtPath:[file stringByAppendingPathExtension:@"jpg"]]) {
        image = [[NWImage alloc] initWithContentsOfFile:[file stringByAppendingPathExtension:@"jpg"]];
    }
    return image;
}


#pragma mark - Cache file convenience

+ (NSString *)cacheFolderWithName:(NSString *)name
{
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    cacheFolder = [cacheFolder stringByAppendingPathComponent:@"pdfcache"];
    NSString *result = [cacheFolder stringByAppendingPathComponent:name];
    return result;
}

+ (NSString *)existingCacheFolderWithName:(NSString *)name
{
    NSString *folder = [self cacheFolderWithName:name];
    if (folder.length) {
        NSFileManager *manager = NSFileManager.defaultManager;
        BOOL directory = NO;
        BOOL success = [manager fileExistsAtPath:folder isDirectory:&directory];
        if (success && directory) {
            return folder;
        }
    }
    return nil;
}

+ (NSString *)ensureCacheFolderWithName:(NSString *)name
{
    NSString *folder = [self cacheFolderWithName:name];
    if (folder.length) {
        NSFileManager *manager = NSFileManager.defaultManager;
        NSError *error = nil;
        BOOL success = [manager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error];
        NWLogWarnIfError(error);
        if (success) {
            return folder;
        }
    }
    return nil;
}

- (void)writeToCacheWithName:(NSString *)name quality:(CGFloat)quality
{
    NSString *folder = [self.class ensureCacheFolderWithName:name];
    if (folder.length) {
        [self writeToFolder:folder quality:quality];
    }
}

- (void)readFromCacheWithName:(NSString *)name
{
    NSString *folder = [self.class existingCacheFolderWithName:name];
    if (folder.length) {
        [self readFromFolder:folder];
    }
}

- (NWImage *)readFromCacheWithName:(NSString *)name page:(NSUInteger)page
{
    NSString *folder = [self.class existingCacheFolderWithName:name];
    if (folder.length) {
        NWImage *result = [self readFromFolder:folder page:page];
        return result;
    }
    return nil;
}

+ (void)precacheWithDocument:(NWPDFDocument *)document name:(NSString *)name pages:(NSArray *)pages size:(CGSize)size
{
    NWPDFCache *cache = [[self alloc] initWithDocument:document];
    __block NSUInteger left = pages.count;
    for (NSNumber *page in pages) {
        [cache imageForPage:page.integerValue within:size priority:kNWPDFCachePriorityLow block:^(NWImage *image) {
            if (--left == 0) {
                [cache writeToCacheWithName:name quality:.8];
            }
        }];
    }
}

@end
