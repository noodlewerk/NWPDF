//
//  NWPDFCommon.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFCommon.h"


@implementation NWPDFCommon

+ (NSString *)nameFromDictionary:(CGPDFDictionaryRef)dict key:(const char *)key
{
    const char *result = NULL;
    if(!CGPDFDictionaryGetName(dict, key, &result)){
        return nil;
    }
    return [NSString stringWithUTF8String:result];
}

+ (NSString *)stringFromDictionary:(CGPDFDictionaryRef)dict key:(const char *)key
{
    CGPDFStringRef ref = NULL;
    if(!CGPDFDictionaryGetString(dict, key, &ref)){
        return nil;
    }
    NSString *result = (__bridge_transfer NSString *)CGPDFStringCopyTextString(ref);
    return result;
}

+ (NSDate *)dateFromDictionary:(CGPDFDictionaryRef)dict key:(const char *)key
{
    CGPDFStringRef ref = NULL;
    if(!CGPDFDictionaryGetString(dict, key, &ref)){
        return nil;
    }
    NSDate *result = (__bridge_transfer NSDate *)CGPDFStringCopyDate(ref);
    return result;
}

+ (NSInteger)integerFromDictionary:(CGPDFDictionaryRef)dict key:(const char *)key defaultsTo:(NSInteger)value
{
    CGPDFInteger result = 0;
    if(!CGPDFDictionaryGetInteger(dict, key, &result)){
        return value;
    }
    return result;
}

+ (NSData *)dataFromDictionary:(CGPDFDictionaryRef)dict key:(const char *)key
{
    CGPDFStreamRef stream = NULL;
    if(CGPDFDictionaryGetStream(dict,key, &stream)){
        NSData *result = (__bridge_transfer NSData *)CGPDFStreamCopyData(stream, CGPDFDataFormatRaw);
        return result;
    }
    CGPDFStringRef string = NULL;
    if(CGPDFDictionaryGetString(dict,key, &string)){
        int length = (int)CGPDFStringGetLength(string);
        char *data = (char *)CGPDFStringGetBytePtr(string);
        return [NSData dataWithBytes:data length:length];
    }
    return nil;
}

+ (NSData *)dataFromArray:(CGPDFArrayRef)array index:(int)index
{
    CGPDFStreamRef ref = NULL;
    if(!CGPDFArrayGetStream(array, index, &ref)){
        return nil;
    }
    NSData *result = (__bridge_transfer NSData *)CGPDFStreamCopyData(ref, CGPDFDataFormatRaw);
    return result;
}

+ (CGRect)rectFrom:(CGPDFArrayRef)array
{
    CGPDFReal lx = 0, ly = 0, ux = 0, uy = 0;
    CGRect result;
    CGPDFArrayGetNumber(array, 0, &lx);
    CGPDFArrayGetNumber(array, 1, &ly);
    CGPDFArrayGetNumber(array, 2, &ux);
    CGPDFArrayGetNumber(array, 3, &uy);
    if(lx > ux){
        result.origin.x = ux;
        result.size.width = lx - ux;
    } else {
        result.origin.x = lx;
        result.size.width = ux - lx;           
    }
    if(ly > uy){
        result.origin.y = uy;
        result.size.height = ly - uy;
    } else {
        result.origin.y = ly;
        result.size.height = uy - ly;           
    }
    return result;
}

+ (CGPDFBox)cgBoxForDisplayBox:(NWPDFDisplayBox)box
{
    switch (box) {
        case kNWPDFDisplayBoxArtBox: return kCGPDFArtBox;
        case kNWPDFDisplayBoxBleedBox: return kCGPDFBleedBox;
        case kNWPDFDisplayBoxCropBox: return kCGPDFCropBox;
        case kNWPDFDisplayBoxMediaBox: return kCGPDFMediaBox;
        case kNWPDFDisplayBoxTrimBox: return kCGPDFTrimBox;
    }
    return -1;
}

@end
