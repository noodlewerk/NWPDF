//
//  NWPDFCache.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
typedef UIImage NWImage;
#else
#import <Cocoa/Cocoa.h>
typedef NSImage NWImage;
#endif

@class NWPDFDocument, NWPDFCacheMonitor;

typedef enum {
    kNWPDFCachePriorityNormal = 0,
    kNWPDFCachePriorityLow = 1,
    kNWPDFCachePriorityBackground = 2
} NWPDFCachePriorityType;



@interface NWPDFCacheKey : NSObject

@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;
@property (nonatomic, readonly) NSUInteger area;

@end



@interface NWPDFCacheTask : NSObject
- (void)cancel;
@end



@interface NWPDFCache : NSObject

@property (nonatomic, strong) NWPDFCacheMonitor *monitor;
@property (nonatomic, readonly) NWPDFDocument *document;

// the byte size of image data in memory
@property (nonatomic, readonly) unsigned long long memoryCacheSize;
@property (nonatomic, assign) unsigned long long memoryCacheSizeMax;

@property (nonatomic, readonly) NSString *pagesString;
@property (nonatomic, readonly) NSUInteger taskCount;

- (id)initWithDocument:(NWPDFDocument *)page;

- (NWPDFCacheTask *)imageForPage:(NSUInteger)index within:(CGSize)within priority:(NWPDFCachePriorityType)priority block:(void(^)(NWImage *))block;
- (NWImage *)imageFromCacheForPage:(NSUInteger)page;

- (void)clear;

- (void)writeToFolder:(NSString *)folder quality:(CGFloat)quality;
- (void)readFromFolder:(NSString *)folder;
- (NWImage *)readFromFolder:(NSString *)folder page:(NSUInteger)page;

- (void)writeToCacheWithName:(NSString *)name quality:(CGFloat)quality;
- (void)readFromCacheWithName:(NSString *)name;
- (NWImage *)readFromCacheWithName:(NSString *)name page:(NSUInteger)page;

- (void)reduceCacheSizeWithFactor:(float)factor;

- (CGSize)sizeForPage:(NSUInteger)index within:(CGSize)within;

+ (void)precacheWithDocument:(NWPDFDocument *)document name:(NSString *)name pages:(NSArray *)pages size:(CGSize)size;

@end
