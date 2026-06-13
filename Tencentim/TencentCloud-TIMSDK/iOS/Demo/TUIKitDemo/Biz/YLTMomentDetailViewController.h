#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTMomentDetailViewController : UIViewController
- (instancetype)initWithMomentId:(int64_t)momentId friendIds:(NSArray<NSString *> *)friendIds;
@end

NS_ASSUME_NONNULL_END
