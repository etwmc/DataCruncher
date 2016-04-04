//
//  DetailViewController.m
//  Cruncher Studio
//
//  Created by Wai Man Chan on 13/10/2015.
//
//

#import "DetailViewController.h"
#import "Cruncher_Studio-Swift.h"

typedef enum : NSUInteger {
    movingViewBound_none = 0,
    movingViewBound_left = 1 << 0,
    movingViewBound_right = 1 << 1,
    movingViewBound_top = 1 << 2,
    movingViewBound_bottom = 1 << 3
} movingViewBound;

@interface DetailViewController () <UIGestureRecognizerDelegate, UICollisionBehaviorDelegate, UIScrollViewDelegate> {
    UIDynamicAnimator *animator;
    UICollisionBehavior *viewBound;
    UIView *movingView;
    movingViewBound movingViewIsBound;
}
@end

@implementation DetailViewController
@synthesize partView, scrollView;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailItem) {
        self.detailDescriptionLabel.text = [self.detailItem description];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:partView];
    viewBound = [[UICollisionBehavior alloc] initWithItems:@[]];
    [viewBound setTranslatesReferenceBoundsIntoBoundaryWithInsets:(UIEdgeInsetsZero)];
    viewBound.translatesReferenceBoundsIntoBoundary = true;
    viewBound.collisionDelegate = self;
    [animator addBehavior:viewBound];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self configureView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [scrollView setZoomScale:0.4 animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addPart:(id)sender {
    CruncherPartViewController *con = [[CruncherPartViewController alloc] initWithNibName:@"CruncherPartViewController" bundle:[NSBundle mainBundle]];
    con.part = [[CruncherPart alloc] initWithConfDict:@{@"Name": @"Test", @"UpdatePeriod": @10}];
    
    [partView addSubview:con.view];
    con.view.center = CGPointMake(1275, 875);
    
    UIPanGestureRecognizer *recog = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(movePart:)];
    [con.view addGestureRecognizer:recog];
    
    [viewBound addItem:con.view];
}

- (void)movePart:(UIPanGestureRecognizer *)sender {
    UIView *view = sender.view;
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            [sender setTranslation:view.frame.origin inView:partView];
            break;
        default:
            break;
    }
    CGPoint vel = [sender translationInView:partView];
    CGSize size = view.frame.size;
    CGRect newFrame = CGRectMake(vel.x, vel.y, size.width, size.height);
    
    if (sender.view == movingView && movingViewIsBound != movingViewBound_none) {
        if (movingViewIsBound == movingViewBound_bottom && [sender velocityInView:view].y>0)
            newFrame.origin.y = partView.frame.size.height - view.frame.size.height;
        if (movingViewIsBound == movingViewBound_top && [sender velocityInView:view].y<0)
            newFrame.origin.y = 0;
        if (movingViewIsBound == movingViewBound_left && [sender velocityInView:view].x<0)
            newFrame.origin.x = 0;
        if (movingViewIsBound == movingViewBound_right && [sender velocityInView:view].x>0)
            newFrame.origin.x = partView.frame.size.width - view.frame.size.width;
        [sender setTranslation:newFrame.origin inView:partView];
    }
    
    view.frame = newFrame;
    
    [animator updateItemUsingCurrentState:view];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return true;
}

-(void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(UIView *)item withBoundaryIdentifier:(id)identifier atPoint:(CGPoint)p{
    item.gestureRecognizers[0].enabled = NO;
    item.gestureRecognizers[0].enabled = YES;
}


-(void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id)item withBoundaryIdentifier:(id)identifier{
    movingViewIsBound = movingViewBound_none;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return partView;
}

- (void)scrollViewDidZoom:(UIScrollView *)_scrollView
{
    UIView *subView = [_scrollView.subviews objectAtIndex:0];
    
    CGFloat offsetX = MAX((_scrollView.bounds.size.width - _scrollView.contentSize.width) * 0.5, 0.0);
    CGFloat offsetY = MAX((_scrollView.bounds.size.height - _scrollView.contentSize.height) * 0.5, 0.0);
    
    subView.center = CGPointMake(_scrollView.contentSize.width * 0.5 + offsetX,
                                 _scrollView.contentSize.height * 0.5 + offsetY);
}

- (IBAction)zoomToNormal:(UITapGestureRecognizer *)sender {
    [scrollView setZoomScale:1 animated:true];
}

@end
