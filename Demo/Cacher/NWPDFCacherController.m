//
//  NWPDFCacherController.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFCacherController.h"
#import "NWPDF.h"


@implementation NWPDFCacherController {
    IBOutlet UISlider *indexSlider;
    IBOutlet UISlider *sizeSlider;
    IBOutlet UILabel *indexLabel;
    IBOutlet UILabel *sizeLabel;
    IBOutlet UIImageView *imageView;
      
    NSUInteger index;
    NSUInteger size;

    NWPDFPagePrefetcher *prefetcher;
    NWPDFThumbPrefetcher *thumbs;
}

@synthesize flipConinuously;


#pragma mark - Object lifecycle

- (id)initWithDocument:(NWPDFDocument *)_document
{
    self = [super init];
    if (self) {
        size = 500;
        NWPDFCache *_cache = [[NWPDFCache alloc] initWithDocument:_document];
        _cache.memoryCacheSizeMax = 10L * 100000;
        prefetcher = [[NWPDFPagePrefetcher alloc] initWithCache:_cache size:CGSizeMake(500, 500)];
        thumbs = [[NWPDFThumbPrefetcher alloc] initWithCache:_cache size:CGSizeMake(38, 38) count:20];
    }
    return self;
}

+ (NSArray *)createImageViewsForThumbs:(NWPDFThumbPrefetcher *)thumbs
{
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:thumbs.count];
    for (NSUInteger i = 0; i < thumbs.count; i++) {
        CGRect frame = CGRectMake(i * thumbs.size.width, 0, thumbs.size.width, thumbs.size.height);
        UIImageView *view = [[UIImageView alloc] initWithFrame:frame];
        view.backgroundColor = UIColor.blueColor;
        view.contentMode = UIViewContentModeCenter;
        [thumbs thumbForIndex:i block:^(UIImage *image){
            view.image = image;
        }];
        [result addObject:view];
    }
    return result;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self update];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSArray *views = [self.class createImageViewsForThumbs:thumbs];
    for (UIView *view in views) {
        [self.view addSubview:view];
    }
}

- (IBAction)valueDidChange:(UISlider *)slider
{
    [self update];
}

- (IBAction)clearTapped:(UIButton *)button
{
    [prefetcher.cache clear];
}


#pragma mark - Drawing

- (void)updateLabels:(NSString *)s
{
    sizeLabel.text = [NSString stringWithFormat:@"%u  %.1fM", size, (double)size * size / 1000 / 1000];
    indexLabel.text = [NSString stringWithFormat:@"%u   %@", index, s];    
}

- (void)draw
{
    UIImage *image = [prefetcher.cache imageFromCacheForPage:index];
    [self updateLabels:[NSString stringWithFormat:@"%.0fx%.0f", image.size.width, image.size.height]];
    imageView.image = image;
}

- (void)reset
{
    [self draw];
}

- (void)flip:(BOOL)backwards
{
    NSInteger direction = backwards ? -1 : 1;
    index = index + direction;
    [self draw];
}

- (void)update
{
    NSUInteger count = prefetcher.cache.document.pageCount;
    NSUInteger _index = MIN((NSUInteger)(indexSlider.value * count), count - 1);
    NSUInteger _size = 100 * (NSUInteger)(sizeSlider.value * sizeSlider.value * 19 + 1); //use 500 to slow things down
    
    if (size != _size) {
        size = _size;
        index = _index;
        [self reset];
        prefetcher.size = CGSizeMake(size, size);
    } else if(index != _index) {
        if (flipConinuously) {
            while (index != _index) {
                NSInteger direction = (index > _index) ? -1 : 1;
                index += direction;
                [self draw];
            }
        } else {
            index = _index;
            [self draw];
        }
    }
}

@end
