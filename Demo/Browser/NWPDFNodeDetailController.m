//
//  NWPDFNodeDetailController.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFNodeDetailController.h"


@implementation NWPDFNodeDetailController {
    NSString *text;
    IBOutlet UITextView *textView;
}

- (id)initWithText:(NSString *)_text
{
    self = [super init];
    if (self) {
        text = _text;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    textView.text = text;
}

@end
