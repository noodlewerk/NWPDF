//
//  NWPDFNode.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFNode.h"
#import "NWPDFDocument.h"
#import "NWPDFPage.h"


static void CollectDictionaryObjects (const char *key, CGPDFObjectRef value, void *info) {
    [(__bridge NSMutableArray *)info addObject:[NWPDFNode toNode:value key:[NSString stringWithUTF8String:key]]];
}

static void FilterForDisplay(char *data, int length) {
    for (int i = 0; i < length; i++) {
        if (data[i] != '\n' && (data[i] < 32 || data[i] > 126)) {
            data[i] = '.';
        }
    }
}

static kNWPDFNodeCompare NWPDFNodesEqual(NWPDFNode *a, NWPDFNode *b, NSMutableSet *equalSet, NSUInteger depth) {
    if (a.uid == b.uid) {
        return kNWPDFNodeCompareEqual;
    }
    NSString *key = [NSString stringWithFormat:@"%i,%i", (int)a.uid, (int)b.uid];
    if ([equalSet containsObject:key]) {
        return kNWPDFNodeCompareEqual;
    }
    if (--depth == 0) {
        return kNWPDFNodeCompareDunno;
    }
    if (![a.key isEqualToString:b.key] || ![a.value isEqualToString:b.value]) {
        return kNWPDFNodeCompareDifferent;
    }
    NSArray *aChildren = a.children;
    NSArray *bChildren = b.children;
    if (aChildren.count != bChildren.count) {
        return kNWPDFNodeCompareDifferent;
    }
    for (NSUInteger i = 0, count = aChildren.count; i < count; i++) {
        switch(NWPDFNodesEqual([aChildren objectAtIndex:i], [bChildren objectAtIndex:i], equalSet, depth)) {
            case kNWPDFNodeCompareDifferent:
                return kNWPDFNodeCompareDifferent;
            case kNWPDFNodeCompareDunno:
                return kNWPDFNodeCompareDunno;
            default:
                break;
        }
    }
    [equalSet addObject:key];
    return kNWPDFNodeCompareEqual;
}


@implementation NWPDFDocumentNode

@synthesize document;

- (id)initWithDocument:(NWPDFDocument *)_document
{
    self = [super init];
    if (self) {
        self.document = _document.ref;
    }
    return self;
}

- (void)setDocument:(CGPDFDocumentRef)_document
{
    CGPDFDocumentRetain(_document);
    CGPDFDocumentRelease(document);
    document = _document;
}

- (void)dealloc
{
    CGPDFDocumentRelease(document); document = NULL;
}

- (NSString *)value
{
    int count = (int)CGPDFDocumentGetNumberOfPages(document);
    return [NSString stringWithFormat:@"#pages = %u",count];
}

- (int)childrenCount
{
    return (int)CGPDFDocumentGetNumberOfPages(document);
}

- (NSArray *)children
{
    int count = (int)CGPDFDocumentGetNumberOfPages(document);
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:count + 3];  
    // add pages
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithFormat:@"Page %u",i];
        CGPDFPageRef page = CGPDFDocumentGetPage(document, i + 1);
        NWPDFPageNode *node = [[NWPDFPageNode alloc] initWithKey:key uid:(NSUInteger)page];
        node.page = page;
        [result addObject:node];
    }
    // add catalog
    CGPDFDictionaryRef catalogRef = CGPDFDocumentGetCatalog(document);
    NWPDFDictionaryNode *catalog = [[NWPDFDictionaryNode alloc] initWithKey:@"Catalog" uid:(NSUInteger)catalogRef];
    catalog.dictionary = catalogRef;
    [result addObject:catalog];
    // add ids
    CGPDFArrayRef idsRef = CGPDFDocumentGetID(document);
    NWPDFArrayNode *ids = [[NWPDFArrayNode alloc] initWithKey:@"ID" uid:(NSUInteger)idsRef];
    ids.array = idsRef;
    [result addObject:ids];
    // add info
    CGPDFDictionaryRef infoRef = CGPDFDocumentGetInfo(document);
    NWPDFDictionaryNode *info = [[NWPDFDictionaryNode alloc] initWithKey:@"Info" uid:(NSUInteger)infoRef];
    info.dictionary = infoRef;
    [result addObject:info];
    return result;
}

@end

@implementation NWPDFPageNode

@synthesize page;

- (id)initWithPage:(NWPDFPage *)_page
{
    self = [super init];
    if (self) {
        self.page = _page.ref;
    }
    return self;
}

- (void)setPage:(CGPDFPageRef)_page
{
    CGPDFPageRetain(_page);
    CGPDFPageRelease(page);
    page = _page;
}

- (void)dealloc
{
    CGPDFPageRelease(page); page = NULL;
}

- (NSString *)value
{
    NSUInteger count = CGPDFDictionaryGetCount(CGPDFPageGetDictionary(page));
    NSArray *children = self.children;
    NSString *s = @"";
    for (NWPDFNode *node in children) {
        s = [s stringByAppendingFormat:@"%@, ", node.key];
    }
    return [NSString stringWithFormat:@"|%u| %@",(int)count,s];
}

- (int)childrenCount
{
    return (int)CGPDFDictionaryGetCount(CGPDFPageGetDictionary(page));
}

- (NSArray *)children
{
    int count = (int)CGPDFDictionaryGetCount(CGPDFPageGetDictionary(page));
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:count];
    CGPDFDictionaryApplyFunction(CGPDFPageGetDictionary(page), CollectDictionaryObjects, (__bridge void *)result);
    for (int i = 0; i < result.count; i++) {
        NSString *s = [[result objectAtIndex:i] key];
        if ([s isEqual:@"Parent"]) {
            [result removeObjectAtIndex:i];
            break;
        }
    }
    return result;
}

@end

@implementation NWPDFArrayNode

@synthesize array;

- (NSString *)value
{
    NSUInteger count = CGPDFArrayGetCount(array);
    NSArray *children = self.children;
    NSString *s = @"";
    for (NWPDFNode *node in children) {
        s = [s stringByAppendingFormat:@"%@, ", node.value];
    }
    return [NSString stringWithFormat:@"[%u] %@",(int)count,s];
}

- (int)childrenCount
{
    return (int)CGPDFArrayGetCount(array);
}

- (NSArray *)children
{
    int count = (int)CGPDFArrayGetCount(array);
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++) {
        CGPDFObjectRef value;
        CGPDFArrayGetObject(array, i, &value);
        NSString *key = [NSString stringWithFormat:@"%d",i];
        NWPDFNode *node = [NWPDFNode toNode:value key:key];
        [result addObject:node];
    }
    return result;
}

@end

@implementation NWPDFDictionaryNode

@synthesize dictionary;

- (NSString *)value
{
    NSUInteger count = CGPDFDictionaryGetCount(dictionary);
    NSArray *children = self.children;
    NSString *s = @"";
    for (NWPDFNode *node in children) {
        s = [s stringByAppendingFormat:@"%@, ", node.key];
    }
    return [NSString stringWithFormat:@"{%u} %@",(int)count,s];
}

- (int)childrenCount
{
    return (int)CGPDFDictionaryGetCount(dictionary);
}

- (NSArray *)children
{
    int count = (int)CGPDFDictionaryGetCount(dictionary);
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:count];
    CGPDFDictionaryApplyFunction(dictionary, CollectDictionaryObjects, (__bridge void *)result);
    return result;
}

@end

@implementation NWPDFStreamNode

@synthesize stream;

- (NSString *)value
{
    CFDataRef content = CGPDFStreamCopyData(stream, NULL);
    NSUInteger length = CFDataGetLength(content);
    char *data = (char *)CFDataGetBytePtr(content);
    FilterForDisplay(data, (int)length);
    NSString *result = [NSString stringWithFormat:@"(%u) %s",(int)length,data];
    CFRelease(content);
    return result;
}

- (int)childrenCount
{
    return (int)CGPDFDictionaryGetCount(CGPDFStreamGetDictionary(stream)) + 1;
}

- (NSArray *)children
{
    CGPDFDictionaryRef dictionary = CGPDFStreamGetDictionary(stream);
    int count = (int)CGPDFDictionaryGetCount(dictionary);
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:count+1];
    
    CFDataRef content = CGPDFStreamCopyData(stream, NULL);
    int length = (int)CFDataGetLength(content);
    char *data = (char *)CFDataGetBytePtr(content);
    FilterForDisplay(data, length);
    NSString *text = [NSString stringWithUTF8String:data];
    NWPDFTextNode *dataNode = [[NWPDFTextNode alloc] initWithKey:@"Data" uid:(NSUInteger)text];
    dataNode.text = text;
    CFRelease(content);
    [result addObject:dataNode];
    
    CGPDFDictionaryApplyFunction(dictionary, CollectDictionaryObjects, (__bridge void *)result);
    return result;
}

@end

@implementation NWPDFNumberNode

@synthesize number;

- (NSString *)value
{
    return [NSString stringWithFormat:@"%@",number];
}

@end

@implementation NWPDFTextNode

@synthesize text;

- (NSString *)value
{
    return text;
}

@end

@implementation NWPDFNullNode

- (NSString *)value
{
    return @"NULL";
}

@end

@implementation NWPDFNode

@synthesize key, uid;

- (id)initWithKey:(NSString *)_key uid:(NSUInteger)_uid
{
    self = [super init];
    if (self) {
        key = _key;
        uid = _uid;
    }
    return self;
}

- (NSString *)value
{
    return nil;
}

- (int)childrenCount
{
    return 0;
}

- (NSArray *)children
{
    return nil;
}

+ (NWPDFNode *)toNode:(CGPDFObjectRef)object key:(NSString *)key
{
    CGPDFObjectType type = CGPDFObjectGetType(object);
    NSUInteger uid = (NSUInteger) object;
    switch (type) {
        case kCGPDFObjectTypeNull: {
            NWPDFNullNode *node = [[NWPDFNullNode alloc] initWithKey:key uid:uid];
            return node;
        }
        case kCGPDFObjectTypeBoolean: {
            CGPDFBoolean value;
            CGPDFObjectGetValue(object, type, &value);
            NWPDFNumberNode *node = [[NWPDFNumberNode alloc] initWithKey:key uid:uid];
            node.number = [NSNumber numberWithBool:value];
            return node;
        }
        case kCGPDFObjectTypeInteger: {
            CGPDFInteger value;
            CGPDFObjectGetValue(object, type, &value);
            NWPDFNumberNode *node = [[NWPDFNumberNode alloc] initWithKey:key uid:uid];
            node.number = [NSNumber numberWithInt:value];
            return node;
        }
        case kCGPDFObjectTypeReal: {
            CGPDFReal value;
            CGPDFObjectGetValue(object, type, &value);
            NWPDFNumberNode *node = [[NWPDFNumberNode alloc] initWithKey:key uid:uid];
            node.number = [NSNumber numberWithFloat:value];
            return node;
        }
        case kCGPDFObjectTypeName: {
            const char *value;
            CGPDFObjectGetValue(object, type, &value);
            NWPDFTextNode *node = [[NWPDFTextNode alloc] initWithKey:key uid:uid];
            node.text = [NSString stringWithUTF8String:value];
            return node;
        }
        case kCGPDFObjectTypeString: {
            CGPDFStringRef value;
            CGPDFObjectGetValue(object, type, &value);
            NWPDFTextNode *node = [[NWPDFTextNode alloc] initWithKey:key uid:uid];
            NSUInteger length = CGPDFStringGetLength(value);
            char *data = (char *)CGPDFStringGetBytePtr(value);
            FilterForDisplay(data, (int)length);
            node.text = [NSString stringWithFormat:@"/%u/ %s",(int)length,data];
            return node;
        }
        case kCGPDFObjectTypeArray: {
            CGPDFArrayRef value;
            CGPDFObjectGetValue(object, type, &value);
            NWPDFArrayNode *node = [[NWPDFArrayNode alloc] initWithKey:key uid:uid];
            node.array = value;
            return node;
        }
        case kCGPDFObjectTypeDictionary: {
            CGPDFDictionaryRef value;
            CGPDFObjectGetValue(object, type, &value);
            NWPDFDictionaryNode *node = [[NWPDFDictionaryNode alloc] initWithKey:key uid:uid];
            node.dictionary = value;
            return node;
        }
        case kCGPDFObjectTypeStream: {
            CGPDFStreamRef value;
            CGPDFObjectGetValue(object, type, &value);
            NWPDFStreamNode *node = [[NWPDFStreamNode alloc] initWithKey:key uid:uid];
            node.stream = value;
            return node;
        }
    }    
    return nil;
}

+ (kNWPDFNodeCompare)isEqual:(NWPDFNode *)a to:(NWPDFNode *)b depth:(NSUInteger)maxDepth
{
    NSMutableSet *set = [[NSMutableSet alloc] init];
    return NWPDFNodesEqual(a, b, set, maxDepth);
}

@end
