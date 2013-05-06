//
//  NWPDFCommon.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef enum {
    kNWPDFDisplayBoxMediaBox = 0, 
    kNWPDFDisplayBoxCropBox = 1, 
    kNWPDFDisplayBoxBleedBox = 2, 
    kNWPDFDisplayBoxTrimBox = 3, 
    kNWPDFDisplayBoxArtBox = 4
} NWPDFDisplayBox;


// Misc conversions from PDF land to NS land.
@interface NWPDFCommon : NSObject

+ (NSString *)nameFromDictionary:(CGPDFDictionaryRef)dictRef key:(const char *)key;
+ (NSString *)stringFromDictionary:(CGPDFDictionaryRef)dictRef key:(const char *)key;
+ (NSDate *)dateFromDictionary:(CGPDFDictionaryRef)dict key:(const char *)key;
+ (NSInteger)integerFromDictionary:(CGPDFDictionaryRef)dictRef key:(const char *)key defaultsTo:(NSInteger)value;
+ (NSData *)dataFromDictionary:(CGPDFDictionaryRef)dictRef key:(const char *)key;
+ (NSData *)dataFromArray:(CGPDFArrayRef)array index:(int)index;
+ (CGRect)rectFrom:(CGPDFArrayRef)array;
+ (CGPDFBox)cgBoxForDisplayBox:(NWPDFDisplayBox)box;

@end
