//
//  NWPDFThumbIndexView.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NWPDFThumbIndexViewDelegate;
@class NWPDFDocument, NWPDFCache, NWPDFThumbPrefetcher;

@interface NWPDFThumbIndexView : UIControl

@property (nonatomic, assign) id <NWPDFThumbIndexViewDelegate> delegate;
@property (nonatomic) NSInteger maximumThumbnails;
@property (nonatomic, readonly) NWPDFThumbPrefetcher *prefetcher;

- (id)initWithDocument:(NWPDFDocument *)_document cache:(NWPDFCache *)cache;

@end

@protocol NWPDFThumbIndexViewDelegate <NSObject>
- (void)thumbIndexView:(NWPDFThumbIndexView *)thumbIndexView didSelectThumbAtIndex:(NSInteger)index;
- (void)thumbIndexView:(NWPDFThumbIndexView *)thumbIndexView didScrollThumbAtIndex:(NSInteger)index;
@end
