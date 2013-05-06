//
//  NWPDFCacheMonitorView.h
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NWPDFCacheMonitor.h"

@interface NWPDFCacheMonitorView : UIView <NWPDFCacheMonitorEventDelegate>

@property (nonatomic, strong) NSString *name;

- (id)initWithFrame:(CGRect)frame name:(NSString *)name;

@end
