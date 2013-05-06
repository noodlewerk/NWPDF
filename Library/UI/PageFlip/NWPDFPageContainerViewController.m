//
//  NWPDFPageContainerViewController.m
//  NWPDF
//
//  Copyright (c) 2012 noodlewerk. All rights reserved.
//

#import "NWPDFPageContainerViewController.h"
#import "NWPDFDocument.h"
#import "NWPDFSinglePageViewController.h"
#import "NWPDFSinglePageView.h"
#import "NWPDFPage.h"

    
CG_INLINE CGFloat evenf(CGFloat f) {
    return (CGFloat) (((int)roundf(f) >> 2) << 2);
};

CG_INLINE CGSize CGSizeEven(CGSize size){size.height = evenf(size.height); size.width = evenf(size.width); return size; };

@interface NWPDFPageContainerViewController (Private)
- (CGRect)rectForPage:(NWPDFPage*)page withinRect:(CGRect)rect zoomScale:(CGFloat)zoomScale;
@end

@implementation NWPDFPageContainerViewController {
    NWPDFDocument* document;
    UIPageViewController* pageViewController;
    UIScrollView* scrollView;
    BOOL ignoreLayout;
    CGRect calcFrame;
}

- (id)initWithDocument:(NWPDFDocument *)_document
{
    self = [super init];
    if (self) {
        document = _document;
    
        pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
        [self addChildViewController:pageViewController];
            
        NWPDFPage* page = [document pageAtIndex:0];
        NWPDFSinglePageViewController* vc = [[NWPDFSinglePageViewController alloc] initWithPDFPage:page];
        [pageViewController setViewControllers:@[vc] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
            
        }];
        
        pageViewController.delegate = self;
        pageViewController.dataSource = self;

    }
    return self;
}
                
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    UIPinchGestureRecognizer* pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(didPinch:)];
    [self.view addGestureRecognizer:pinch];
//    scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
//    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    scrollView.backgroundColor = [UIColor yellowColor];
//    scrollView.delegate = self;
//    scrollView.minimumZoomScale = 1.0;
//    scrollView.maximumZoomScale = 10.0;
//    [scrollView addSubview:pageViewController.view];
    
    [self.view addSubview:pageViewController.view];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if(ignoreLayout)
        return;
    
    NWPDFSinglePageViewController *singlePageViewController = (NWPDFSinglePageViewController*)[[pageViewController viewControllers] objectAtIndex:0];
    CGRect pdfRect = [self rectForPage:singlePageViewController.page withinRect:self.view.bounds zoomScale:1.0];
    pageViewController.view.frame = pdfRect;
    calcFrame = pdfRect;
    pageViewController.view.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return pageViewController.view;
}

- (void)didPinch:(UIPinchGestureRecognizer*)pinch
{
    switch (pinch.state) {
        case UIGestureRecognizerStateBegan:
            ignoreLayout = YES;
            break;
        case UIGestureRecognizerStateRecognized:
            ignoreLayout = NO;
            break;
        case UIGestureRecognizerStateChanged: 
        {
            CGFloat scale = MAX(MIN([pinch scale], 100), 0.01);
            
            calcFrame.size.width *= scale;
            calcFrame.size.height *= scale;
            CGRect newFrame = calcFrame;
            
            //NWPDFSinglePageViewController *singlePageViewController = (NWPDFSinglePageViewController*)[[pageViewController viewControllers] objectAtIndex:0];
            
            if(calcFrame.size.width > self.view.frame.size.width){
                newFrame.size.width = self.view.frame.size.width;
            }
            if(calcFrame.size.height > self.view.frame.size.height){
                newFrame.size.height = self.view.frame.size.height;
            }
        
            pageViewController.view.frame = newFrame;
            pageViewController.view.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
            pinch.scale = 1.0;
            break;
        }
        case UIGestureRecognizerStateFailed:
            ignoreLayout = NO;
            break;
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateCancelled:
            ignoreLayout = NO;            
            break;
        default:
            break;
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    pageViewController.view.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
}

- (CGRect)rectForPage:(NWPDFPage*)page withinRect:(CGRect)rect zoomScale:(CGFloat)zoomScale{
    CGRect contentRect;
    CGFloat ratio = page.pageRatio;
    if(ratio < 1.f){
        // Landscape page
        CGFloat height = evenf(rect.size.width * ratio); // evenf because we're using .center later on
        CGFloat anotherRatio = 1.0;
        if(height > rect.size.height){
            anotherRatio = rect.size.height / height;
            height = rect.size.height;
        }
        contentRect = CGRectMake(0, 0, evenf(rect.size.width) * anotherRatio, height);
    } else {
        // Portrait page
        CGFloat width = evenf(rect.size.height / ratio); // evenf because we're using .center later on
        CGFloat anotherRatio = 1.0;
        if(width > rect.size.width){
            anotherRatio = rect.size.width / width;
            width = rect.size.width;
        }
        contentRect = CGRectMake(0, 0, width, evenf(rect.size.height) * anotherRatio);
    }
    return contentRect;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

// Sent when a gesture-initiated transition ends. The 'finished' parameter indicates whether the animation finished, while the 'completed' parameter indicates whether the transition completed or bailed out (if the user let go early).
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    
}

// Delegate may specify a different spine location for after the interface orientation change. Only sent for transition style 'UIPageViewControllerTransitionStylePageCurl'.
// Delegate may set new view controllers or update double-sided state within this method's implementation as well.
/*
 - (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
 
 }
 */
// In terms of navigation direction. For example, for 'UIPageViewControllerNavigationOrientationHorizontal', view controllers coming 'before' would be to the left of the argument view controller, those coming 'after' would be to the right.
// Return 'nil' to indicate that no more progress can be made in the given direction.
// For gesture-initiated transitions, the page view controller obtains view controllers via these methods, so use of setViewControllers:direction:animated:completion: is not required.
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(NWPDFSinglePageViewController *)viewController
{
    NSInteger index = viewController.page.index;
    if(index > 0){
        NWPDFPage* page = [document pageAtIndex:--index];
        NWPDFSinglePageViewController* vc = [[NWPDFSinglePageViewController alloc] initWithPDFPage:page];
        return vc;
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(NWPDFSinglePageViewController *)viewController
{
    NSInteger index = viewController.page.index;
    if(index < [document pageCount] - 1){
        NWPDFPage* page = [document pageAtIndex:++index];
        NWPDFSinglePageViewController* vc = [[NWPDFSinglePageViewController alloc] initWithPDFPage:page];
        return vc;
    }
    return nil;
}


@end
