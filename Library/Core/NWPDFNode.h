//
//  NWPDFNode.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef enum {
    kNWPDFNodeCompareEqual = 1,
    kNWPDFNodeCompareDifferent = 0,
    kNWPDFNodeCompareDunno = -1
} kNWPDFNodeCompare;

@class NWPDFDocument, NWPDFPage;


@interface NWPDFNode : NSObject

@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *value;
@property (nonatomic, readonly) int childrenCount;
@property (nonatomic, readonly) NSArray *children;
// A unique number identifying this and equal nodes
@property (nonatomic, readonly) NSUInteger uid;

- (id)initWithKey:(NSString *)key uid:(NSUInteger)uid;
// Creates a node based on a pdf object and a dictionary key
+ (NWPDFNode *)toNode:(CGPDFObjectRef)object key:(NSString *)key;
// Recursively compares two nodes
+ (kNWPDFNodeCompare)isEqual:(NWPDFNode *)a to:(NWPDFNode *)b depth:(NSUInteger)maxDepth;

@end


// An entire PDF document, containing pages, catalog, info, etc.
@interface NWPDFDocumentNode : NWPDFNode
@property(nonatomic, assign) CGPDFDocumentRef document;
- (id)initWithDocument:(NWPDFDocument *)document;
@end


// A single PDF page, containing boxes, xobjects, annotations, etc.
@interface NWPDFPageNode : NWPDFNode
@property(nonatomic, assign) CGPDFPageRef page;
- (id)initWithPage:(NWPDFPage *)page;
@end


// Your average array
@interface NWPDFArrayNode : NWPDFNode
@property(nonatomic, assign) CGPDFArrayRef array;
@end


// Your average dictionary
@interface NWPDFDictionaryNode : NWPDFNode
@property(nonatomic, assign) CGPDFDictionaryRef dictionary;
@end


// A PDF stream, which is a dictionary with data
@interface NWPDFStreamNode : NWPDFNode
@property(nonatomic, assign) CGPDFStreamRef stream;
@end


// A numeric value, integer or floating point
@interface NWPDFNumberNode : NWPDFNode
@property(nonatomic, strong) NSNumber *number;
@end


// A string of characters, not necessary readable
@interface NWPDFTextNode : NWPDFNode
@property(nonatomic, strong) NSString *text;
@end


// An empty node, based on the PDF Null type
@interface NWPDFNullNode : NWPDFNode
@end
