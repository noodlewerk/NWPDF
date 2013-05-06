//
//  NWPDFCacheMonitorView.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFCacheMonitorView.h"


@implementation NWPDFCacheMonitorView {
    UILabel *infoLabel;
}

@synthesize name;

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame name:@""];
}

- (id)initWithFrame:(CGRect)frame name:(NSString *)_name
{
    self = [super initWithFrame:frame];
    if (self) {
        name = _name;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:.5];
        
        infoLabel = [[UILabel alloc] initWithFrame:self.bounds];
        infoLabel.textColor = UIColor.whiteColor;
        infoLabel.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:11];
        infoLabel.backgroundColor = UIColor.clearColor;
        [self addSubview:infoLabel];
    }
    return self;
}

- (void)monitor:(NWPDFCacheMonitor *)monitor hadEvent:(NWPDFCacheEventType)event
{
    NSString *string = [NSString stringWithFormat:@"[%@] images #:%i size:%@", name, monitor.cacheCount, [NWPDFCacheMonitor stringFromSize:monitor.cacheSize]];
    dispatch_async(dispatch_get_main_queue(), ^{
        infoLabel.text = string;
    });
}

@end
