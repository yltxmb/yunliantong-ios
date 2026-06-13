#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTMomentImageBrowseViewController : UIViewController

+ (void)presentFrom:(UIViewController *)host urls:(NSArray<NSString *> *)urls startIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
