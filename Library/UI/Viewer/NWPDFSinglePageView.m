//
//  NWPDFSinglePageView.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFSinglePageView.h"
#import "NWPDFPage.h"
#import "NWPDF.h"


@implementation NWPDFPageView {
    NWPDFPage *page;
}

- (id)initWithFrame:(CGRect)frame page:(NWPDFPage *)_page
{
    self = [super initWithFrame:frame];
    if (self) {
        CATiledLayer *tiledLayer = (CATiledLayer*)self.layer;
        tiledLayer.levelsOfDetail = 2;
        tiledLayer.levelsOfDetailBias = 4;
        
        page = _page;
        
        // to handle the interaction between CATiledLayer and high resolution screens, we need to manually set the
        // tiling view's contentScaleFactor to 1.0. (If we omitted this, it would be 2.0 on high resolution screens,
        // which would cause the CATiledLayer to ask us for tiles of the wrong scales.)
        self.contentScaleFactor = 1.0;
    }
    return self;
}

+ (Class)layerClass {
    return [CATiledLayer class];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGSize tileSize = self.bounds.size;
    if (tileSize.width > 0 && tileSize.height > 0) {
        ((CATiledLayer*)self.layer).tileSize = tileSize;
    }
}

-(void)drawRect:(CGRect)r
{
    // UIView uses the existence of -drawRect: to determine if it should allow its CALayer
    // to be invalidated, which would then lead to the layer creating a backing store and
    // -drawLayer:inContext: being called.
    // By implementing an empty -drawRect: method, we allow UIKit to continue to implement
    // this logic, while doing our real drawing work inside of -drawLayer:inContext:
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    // TODO: these may speedup the rendering
    // CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    // CGContextSetRenderingIntent(context, kCGRenderingIntentDefault);
    
    // TODO: drawInContext invoked twice, OS bug?
//    NWLogInfo(@"Drawlayer");
    [page drawInContext:context pageRect:self.bounds];
}

@end

@implementation NWPDFSinglePageView {
    UIImageView *imageView;
    BOOL shouldAnimate;
}

@synthesize pdfView;
@synthesize page;
@synthesize annotationViews;
@synthesize annotationDelegate;

- (id)initWithPage:(NWPDFPage *)_page annotationDelegate:(id<NWPDFSinglePageViewDelegate>)_annotationDelegate {
    self = [super init];
    if (self) {
        page = _page;
        annotationDelegate = _annotationDelegate;
        
        self.backgroundColor = [UIColor whiteColor];
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.7f;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowRadius = 4.0f;
        self.layer.masksToBounds = NO;
        
        imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:imageView];
        
        pdfView = [[NWPDFPageView alloc] initWithFrame:self.bounds page:page];
        [self addSubview:pdfView];
        
        //add annotations
        NSArray *annotations = [page extractAnnotations];
        annotationViews = [NSMutableArray arrayWithCapacity:annotations.count];
        
        for(NWPDFAnnotation* annotation in annotations){
            if([annotationDelegate respondsToSelector:@selector(pageView:viewForAnnotation:)]){
                UIView <NWPDFAnnotationView> *annotationView = [annotationDelegate pageView:self viewForAnnotation:annotation];
                if (annotationView) {
                    [self addSubview:annotationView];
                    [annotationViews addObject:annotationView];
                }
            }
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillChangeStatusBarOrientationNotification:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    CGRect newRect = CGRectInset(self.bounds, -2, -2);
    id fromPath = (id)self.layer.shadowPath;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:newRect].CGPath;
    
    if(shouldAnimate){
        CABasicAnimation* shadowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
        [shadowAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        shadowAnimation.fromValue = fromPath;
        shadowAnimation.toValue = (id)[UIBezierPath bezierPathWithRect:newRect].CGPath;
        shadowAnimation.duration = 0.4;//[[UIApplication sharedApplication] statusBarOrientationAnimationDuration];
        [self.layer addAnimation:shadowAnimation forKey:@"shadowPath"];
        shouldAnimate = NO;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    pdfView.frame = self.bounds;
    
    for(UIView <NWPDFAnnotationView> *annotationView in annotationViews){
        CGRect aRect = [page viewRectFromPDFRect:annotationView.annotation.bounds pageRect:self.bounds];
        annotationView.frame = CGRectIntegral(aRect);
    }
}

- (void)applicationWillChangeStatusBarOrientationNotification:(NSNotification *)notification {
    NSNumber* boolNumber = [[notification userInfo] objectForKey:@"UIDeviceOrientationRotateAnimatedUserInfoKey"];
    if (boolNumber) shouldAnimate = [boolNumber boolValue];
    else shouldAnimate = YES; 
}
    
- (NWPDFPage *)page {
    return page;
}

- (void)setImage:(UIImage *)image {
    imageView.image = image;
}

@end


@implementation NWPDFSinglePageZoomView {
    NWPDFSinglePageView *singlePageView;
}

@synthesize page, annotationDelegate;

- (id)initWithPage:(NWPDFPage *)_page annotationDelegate:(id<NWPDFSinglePageViewDelegate>)_annotationDelegate {
    self = [super init];
    if (self) {
        page = _page;
        annotationDelegate = _annotationDelegate;
        self.minimumZoomScale = 1.0;
        self.maximumZoomScale = 10;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
        singlePageView = [[NWPDFSinglePageView alloc] initWithPage:page annotationDelegate:annotationDelegate];
        [self addSubview:singlePageView];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.zoomScale = 1.0;
    CGRect rect = [self rectForPage:page];
    singlePageView.frame = rect;
}

- (CGRect)rectForPage:(NWPDFPage *)page {
    CGRect rect = [self.page pageWithin:self.bounds.size];
    return CGRectIntegral(rect);
}

- (void)setImage:(UIImage *)image {
    [singlePageView setImage:image];
}

- (NSArray *)annotationViews {
    return singlePageView.annotationViews;
}

- (NWPDFPageView *)pdfView {
    return singlePageView.pdfView;
}

#pragma mark -
#pragma mark UIScrollView delegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return singlePageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)aScrollView {
    CGFloat offsetX = (self.bounds.size.width > self.contentSize.width)? 
    (self.bounds.size.width - self.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (self.bounds.size.height > self.contentSize.height)? 
    (self.bounds.size.height - self.contentSize.height) * 0.5 : 0.0;
    singlePageView.center = CGPointMake(self.contentSize.width * 0.5 + offsetX, 
                                     self.contentSize.height * 0.5 + offsetY);    
}

- (void)setContentScale:(CGFloat)scale onView:(UIView *)aView {
    [aView setContentScaleFactor:scale];
    for(UIView *subview in aView.subviews){
        [self setContentScale:scale onView:subview];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    // This wil redraw the annotation text
    scale *= [[[scrollView window] screen] scale];
    for(UIView* aView in singlePageView.annotationViews) {
        [self setContentScale:scale onView:aView];
    }
};


@end 
