#import "YLTMomentImageGridView.h"
#import <SDWebImage/UIImageView+WebCache.h>

static const NSInteger kGridTagBase = 8800;
static const NSInteger kCols = 3;
static const CGFloat kGap = 4;

@interface YLTMomentImageGridView ()
@property (nonatomic, copy) NSArray<NSString *> *boundUrls;
@end

@implementation YLTMomentImageGridView

- (void)prepareForReuse {
    for (UIView *v in self.subviews) {
        [v removeFromSuperview];
    }
    self.boundUrls = @[];
}

- (void)bindImageUrls:(NSArray<NSString *> *)urls maxWidth:(CGFloat)maxWidth {
    [self prepareForReuse];
    self.boundUrls = [urls copy];
    if (urls.count == 0) {
        self.frame = CGRectMake(0, 0, maxWidth, 0);
        return;
    }
    NSInteger count = MIN((NSInteger)urls.count, 9);
    NSInteger cols = count == 4 ? 2 : kCols;
    NSInteger rows = (count + cols - 1) / cols;
    CGFloat cell = 0;
    if (count == 1) {
        cell = MIN(maxWidth * 0.55, 180);
    } else {
        cell = floor((maxWidth - kGap * (cols - 1)) / cols);
    }
    CGFloat totalH = rows * cell + MAX(0, rows - 1) * kGap;
    self.frame = CGRectMake(0, 0, maxWidth, totalH);
    for (NSInteger i = 0; i < count; i++) {
        NSInteger r = i / cols;
        NSInteger c = i % cols;
        CGFloat x = c * (cell + kGap);
        CGFloat y = r * (cell + kGap);
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, cell, cell)];
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        iv.layer.cornerRadius = 4;
        iv.userInteractionEnabled = YES;
        iv.tag = kGridTagBase + i;
        [iv sd_setImageWithURL:[NSURL URLWithString:urls[(NSUInteger)i]]];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        [iv addGestureRecognizer:tap];
        [self addSubview:iv];
    }
}

- (void)onTap:(UITapGestureRecognizer *)gr {
    if (!self.onImageTapped || self.boundUrls.count == 0) {
        return;
    }
    UIView *v = gr.view;
    NSInteger idx = v.tag - kGridTagBase;
    if (idx < 0 || idx >= (NSInteger)self.boundUrls.count) {
        idx = 0;
    }
    self.onImageTapped(self.boundUrls, idx);
}

@end
