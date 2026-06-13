#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTMomentImageGridView : UIView

@property (nonatomic, copy, nullable) void (^onImageTapped)(NSArray<NSString *> *urls, NSInteger index);

- (void)bindImageUrls:(NSArray<NSString *> *)urls maxWidth:(CGFloat)maxWidth;

@end

NS_ASSUME_NONNULL_END
