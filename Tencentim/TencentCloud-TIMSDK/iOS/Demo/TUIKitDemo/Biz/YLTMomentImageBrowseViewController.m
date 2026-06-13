#import "YLTMomentImageBrowseViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface YLTMomentImageBrowsePage : UIViewController <UIScrollViewDelegate>
@property (nonatomic, copy) NSString *url;
@end

@implementation YLTMomentImageBrowsePage

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scroll.minimumZoomScale = 1;
    scroll.maximumZoomScale = 3;
    scroll.delegate = (id<UIScrollViewDelegate>)self;
    [self.view addSubview:scroll];
    UIImageView *iv = [[UIImageView alloc] initWithFrame:scroll.bounds];
    iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.tag = 501;
    [scroll addSubview:iv];
    if (self.url.length) {
        [iv sd_setImageWithURL:[NSURL URLWithString:self.url]];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return [scrollView viewWithTag:501];
}

@end

@interface YLTMomentImageBrowseViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
@property (nonatomic, copy) NSArray<NSString *> *urls;
@property (nonatomic, assign) NSInteger startIndex;
@property (nonatomic, strong) UIPageViewController *pager;
@property (nonatomic, strong) UILabel *indexLabel;
@end

@implementation YLTMomentImageBrowseViewController

+ (void)presentFrom:(UIViewController *)host urls:(NSArray<NSString *> *)urls startIndex:(NSInteger)index {
    NSMutableArray *filtered = [NSMutableArray array];
    for (NSString *u in urls) {
        if (u.length) {
            [filtered addObject:u];
        }
    }
    if (filtered.count == 0 || !host) {
        return;
    }
    NSInteger mapped = 0;
    if (index >= 0 && index < (NSInteger)urls.count && urls[(NSUInteger)index].length) {
        for (NSInteger k = 0; k < index; k++) {
            if (urls[(NSUInteger)k].length) {
                mapped++;
            }
        }
    }
    mapped = MAX(0, MIN(mapped, (NSInteger)filtered.count - 1));
    YLTMomentImageBrowseViewController *vc = [[YLTMomentImageBrowseViewController alloc] init];
    vc.urls = filtered;
    vc.startIndex = mapped;
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [host presentViewController:vc animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.pager = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                  navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                options:nil];
    self.pager.dataSource = self;
    self.pager.delegate = self;
    [self addChildViewController:self.pager];
    self.pager.view.frame = self.view.bounds;
    self.pager.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.pager.view];
    [self.pager didMoveToParentViewController:self];
    YLTMomentImageBrowsePage *first = [self pageAtIndex:self.startIndex];
    if (first) {
        [self.pager setViewControllers:@[ first ] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(16, 52, 64, 36);
    [close setTitle:@"关闭" forState:UIControlStateNormal];
    [close setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [close addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:close];
    self.indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 52, self.view.bounds.size.width, 36)];
    self.indexLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.indexLabel.textAlignment = NSTextAlignmentCenter;
    self.indexLabel.textColor = UIColor.whiteColor;
    self.indexLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.indexLabel];
    [self updateIndexLabel:self.startIndex];
}

- (YLTMomentImageBrowsePage *)pageAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.urls.count) {
        return nil;
    }
    YLTMomentImageBrowsePage *p = [[YLTMomentImageBrowsePage alloc] init];
    p.url = self.urls[(NSUInteger)index];
    return p;
}

- (void)updateIndexLabel:(NSInteger)index {
    self.indexLabel.text = [NSString stringWithFormat:@"%ld / %ld", (long)(index + 1), (long)self.urls.count];
}

- (void)onClose {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger idx = [self indexOfPage:(YLTMomentImageBrowsePage *)viewController];
    return idx > 0 ? [self pageAtIndex:idx - 1] : nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger idx = [self indexOfPage:(YLTMomentImageBrowsePage *)viewController];
    return idx + 1 < (NSInteger)self.urls.count ? [self pageAtIndex:idx + 1] : nil;
}

- (NSInteger)indexOfPage:(YLTMomentImageBrowsePage *)page {
    for (NSUInteger i = 0; i < self.urls.count; i++) {
        if ([page.url isEqualToString:self.urls[i]]) {
            return (NSInteger)i;
        }
    }
    return 0;
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    if (!completed) {
        return;
    }
    YLTMomentImageBrowsePage *cur = (YLTMomentImageBrowsePage *)pageViewController.viewControllers.firstObject;
    [self updateIndexLabel:[self indexOfPage:cur]];
}

@end
