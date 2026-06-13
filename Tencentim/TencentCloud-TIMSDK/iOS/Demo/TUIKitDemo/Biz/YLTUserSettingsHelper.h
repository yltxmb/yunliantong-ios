#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTUserSettingsHelper : NSObject

+ (BOOL)isNotifySoundEnabled;
+ (void)setNotifySoundEnabled:(BOOL)enabled;

+ (BOOL)isNotifyVibrateEnabled;
+ (void)setNotifyVibrateEnabled:(BOOL)enabled;

/** 将通知声音偏好同步到 TUIChat 离线推送铃声开关。 */
+ (void)applyNotificationPreferences;

+ (NSString *)summarizeFriendAllowType:(NSInteger)allowType;
+ (void)presentFriendAllowTypePickerFrom:(UIViewController *)vc
                             currentType:(NSInteger)allowType
                              completion:(nullable void (^)(NSInteger newType))completion;

@end

NS_ASSUME_NONNULL_END
