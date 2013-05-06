//
//  NWPDFDocument.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFDocument.h"
#import "NWPDFNode.h"
#import "NWPDFPage.h"
#import "NWPDFInformation.h"


@implementation NWPDFDocument

@synthesize ref;


#pragma mark - Object lifecycle

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        ref = CGPDFDocumentCreateWithURL((__bridge CFURLRef)url);
    }
    return self;
}

- (id)initWithDataProvider:(CGDataProviderRef)dataProvider
{
    self = [super init];
    if (self) {
        ref = CGPDFDocumentCreateWithProvider(dataProvider);
    }
    return self;
}

- (void)dealloc
{
    CGPDFDocumentRelease(ref); ref = NULL;
}


#pragma mark - Basic properties

- (BOOL)allowsCopying
{
    return CGPDFDocumentAllowsCopying(ref);
}

- (BOOL)allowsPrinting
{
    return CGPDFDocumentAllowsPrinting(ref);
}

- (NSInteger)minorVersion
{
    int result, dummy;
    CGPDFDocumentGetVersion(ref, &dummy, &result);
    return result;
}

- (NSInteger)majorVersion
{
    int result, dummy;
    CGPDFDocumentGetVersion(ref, &result, &dummy);
    return result;
}

- (BOOL)isEncrypted
{
    return CGPDFDocumentIsEncrypted(ref);
}

- (BOOL)isLocked
{
    return !CGPDFDocumentIsUnlocked(ref);
}

- (BOOL)unlockWithPassword:(NSString *)password
{
    if (!password) return NO;
    return CGPDFDocumentUnlockWithPassword(ref, password.UTF8String);
}

- (NSUInteger)pageCount
{
    return CGPDFDocumentGetNumberOfPages(ref);
}


#pragma mark - Sub wrappers

- (NWPDFInformation *)info
{
    return [[NWPDFInformation alloc] initWithDocument:self];
}

// TODO: consider making a NWPDFCatalog
- (NWPDFDictionaryNode *)catalog
{
    CGPDFDictionaryRef dictionary = CGPDFDocumentGetCatalog(ref);
    NWPDFDictionaryNode *result = [[NWPDFDictionaryNode alloc] initWithKey:@"catalog" uid:(NSUInteger)dictionary];
    result.dictionary = dictionary;
    return result;
}

// TODO: consider making a NWPDFIdentifier
- (NWPDFArrayNode *)identifier
{
    CGPDFArrayRef array = CGPDFDocumentGetID(ref);
    NWPDFArrayNode *result = [[NWPDFArrayNode alloc] initWithKey:@"id" uid:(NSUInteger)array];
    result.array = array;
    return result;
}

- (NWPDFPage *)pageAtIndex:(NSUInteger)_index
{
    if (_index < self.pageCount) {
        return [[NWPDFPage alloc] initWithDocument:self index:_index];
    }
    return nil;
}


#pragma mark - Password

- (BOOL)guessPassword
{
    NSArray *candidates = @[@"", @" ", @"password"];
    for (NSString *candidate in candidates) {
        if ([self unlockWithPassword:candidate]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark - Logging

- (NSString *)about
{
    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"<%@>", NSStringFromClass([self class])];
    [result appendFormat:@"\npageCount       : %u", (int)self.pageCount];
    [result appendFormat:@"\nminorVersion    : %u", (int)self.minorVersion];
    [result appendFormat:@"\nmajorVersion    : %u", (int)self.majorVersion];
    [result appendFormat:@"\nisEncrypted     : %@", self.isEncrypted?@"YES":@"NO"];
    [result appendFormat:@"\nisLocked        : %@", self.isLocked?@"YES":@"NO"];
    [result appendFormat:@"\nallowsCopying   : %@", self.allowsCopying?@"YES":@"NO"];
    [result appendFormat:@"\nallowsPrinting  : %@", self.allowsPrinting?@"YES":@"NO"];
    return result;
}

@end
