#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTMomentPublishViewController : UIViewController
@property (nonatomic, copy) void (^onPublished)(void);
- (instancetype)initWithFriendIds:(NSArray<NSString *> *)friendIds;
@end

NS_ASSUME_NONNULL_END
