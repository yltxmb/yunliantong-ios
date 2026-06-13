#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 扫码 / 搜索后跳转加好友或发消息（对齐 Android QrAddFriendNavigator）
@interface YLTAddFriendNavigator : NSObject

+ (void)openAddFriendFromViewController:(UIViewController *)fromVC userId:(NSString *)userId;

+ (void)presentScanFromViewController:(UIViewController *)fromVC;

@end

NS_ASSUME_NONNULL_END
