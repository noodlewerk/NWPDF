//
//  NWPDFInformation.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFInformation.h"
#import "NWPDFDocument.h"
#import "NWPDFCommon.h"


@implementation NWPDFInformation

@synthesize ref, document;


#pragma mark - Object lifecycle

- (id)initWithDocument:(NWPDFDocument *)_document
{
    self = [super init];
    if(self){
        document = _document;
        ref = CGPDFDocumentGetInfo(document.ref);
    }
    return self;
}


#pragma mark - Basic properties

- (NSString *)title
{
    return [NWPDFCommon stringFromDictionary:ref key:"Title"];
}

- (NSString *)author
{
    return [NWPDFCommon stringFromDictionary:ref key:"Author"];
}

- (NSString *)subject
{
    return [NWPDFCommon stringFromDictionary:ref key:"Subject"];
}

- (NSString *)keywords
{
    return [NWPDFCommon stringFromDictionary:ref key:"Keywords"];
}

- (NSString *)creator
{
    return [NWPDFCommon stringFromDictionary:ref key:"Creator"];
}

- (NSString *)producer
{
    return [NWPDFCommon stringFromDictionary:ref key:"Producer"];
}

- (NSDate *)creationDate
{
    return [NWPDFCommon dateFromDictionary:ref key:"CreationDate"];
}

- (NSDate *)modificationDate
{
    return [NWPDFCommon dateFromDictionary:ref key:"ModDate"];
}

- (NSString *)trapped
{
    return [NWPDFCommon nameFromDictionary:ref key:"Trapped"];
}

- (CGPDFDictionaryRef)ref
{
    return ref;
}


#pragma mark - Logging

- (NSString *)about
{
    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"<%@>", NSStringFromClass([self class])];
    if (self.title)            [result appendFormat:@"\ntitle           : %@", self.title];
    if (self.author)           [result appendFormat:@"\nauthor          : %@", self.author];
    if (self.subject)          [result appendFormat:@"\nsubject         : %@", self.subject];
    if (self.keywords)         [result appendFormat:@"\nkeywords        : %@", self.keywords];
    if (self.creator)          [result appendFormat:@"\ncreator         : %@", self.creator];
    if (self.producer)         [result appendFormat:@"\nproducer        : %@", self.producer];
    if (self.creationDate)     [result appendFormat:@"\ncreationDate    : %@", self.creationDate];
    if (self.modificationDate) [result appendFormat:@"\nmodificationDate: %@", self.modificationDate];
    if (self.trapped)          [result appendFormat:@"\ntrapped         : %@", self.trapped];
    return result;
}

@end
