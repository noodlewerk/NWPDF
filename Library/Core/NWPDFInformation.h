//
//  NWPDFInformation.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class NWPDFDocument;

@interface NWPDFInformation : NSObject

@property (nonatomic, readonly) CGPDFDictionaryRef ref;
@property (nonatomic, readonly) NWPDFDocument *document;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *author;
@property (nonatomic, readonly) NSString *subject;
@property (nonatomic, readonly) NSString *keywords;
@property (nonatomic, readonly) NSString *creator;
@property (nonatomic, readonly) NSString *producer;
@property (nonatomic, readonly) NSDate *creationDate;
@property (nonatomic, readonly) NSDate *modificationDate;
@property (nonatomic, readonly) NSString *trapped;

- (id) initWithDocument:(NWPDFDocument *)document;

@end
