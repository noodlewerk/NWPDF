//
//  NWPDFDocument.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class NWPDFPage, NWPDFDictionaryNode, NWPDFArrayNode, NWPDFInformation;

// An Objective-C wrapper for CGPDFDocument.
@interface NWPDFDocument : NSObject

// The wrapped CGPDFDocument, allows access to the underlying datastructure.
@property (nonatomic, readonly) CGPDFDocumentRef ref;

// The number of pages available in this document. Wraps CGPDFDocumentGetNumberOfPages.
@property (nonatomic, readonly) NSUInteger pageCount;

// Wraps CGPDFDocumentAllowsCopying.
@property (nonatomic, readonly) BOOL allowsCopying;

// Wraps CGPDFDocumentAllowsPrinting.
@property (nonatomic, readonly) BOOL allowsPrinting;

// Wraps CGPDFDocumentIsEncrypted.
@property (nonatomic, readonly) BOOL isEncrypted;

// Wraps CGPDFDocumentIsUnlocked.
@property (nonatomic, readonly) BOOL isLocked;

// Wraps CGPDFDocumentGetVersion.
@property (nonatomic, readonly) NSInteger minorVersion;

// Wraps CGPDFDocumentGetVersion.
@property (nonatomic, readonly) NSInteger majorVersion;

// The 'id' array in the document root.
@property (nonatomic, readonly) NWPDFArrayNode *identifier;

// Wraps CGPDFDocumentGetInfo.
@property (nonatomic, readonly) NWPDFInformation *info;

// The 'catalog' array in the document root.
@property (nonatomic, readonly) NWPDFDictionaryNode *catalog;

// Wraps CGPDFDocumentCreateWithURL.
- (id)initWithURL:(NSURL *)url;

// Wraps CGPDFDocumentCreateWithProvider.
- (id)initWithDataProvider:(CGDataProviderRef)dataProvider;

// Returns the page at given index, starting at 0.
- (NWPDFPage *)pageAtIndex:(NSUInteger)index;

// Attempts to unlock this document with given password.
- (BOOL)unlockWithPassword:(NSString *)password;

// Attempts to unlock this document using a small set of standard passwords.
- (BOOL)guessPassword;

@end
