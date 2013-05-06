//
//  NWPDFCacherController.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NWPDFDocument;

@interface NWPDFCacherController : UIViewController

@property (nonatomic, assign) BOOL flipConinuously;

- (id)initWithDocument:(NWPDFDocument *)document;

@end
