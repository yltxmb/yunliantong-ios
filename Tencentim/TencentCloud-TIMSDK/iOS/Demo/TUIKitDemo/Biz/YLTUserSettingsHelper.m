#import "YLTUserSettingsHelper.h"
#import <ImSDK_Plus/ImSDK_Plus.h>
#import <TUICore/TUIConfig.h>

static NSString *const kNotifySound = @"YLT_demo_notify_sound_enabled";
static NSString *const kNotifyVibrate = @"YLT_demo_notify_vibrate_enabled";

@implementation YLTUserSettingsHelper

+ (BOOL)isNotifySoundEnabled {
    if ([NSUserDefaults.standardUserDefaults objectForKey:kNotifySound] == nil) {
        return YES;
    }
    return [NSUserDefaults.standardUserDefaults boolForKey:kNotifySound];
}

+ (void)setNotifySoundEnabled:(BOOL)enabled {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kNotifySound];
    [NSUserDefaults.standardUserDefaults synchronize];
    [self applyNotificationPreferences];
}

+ (BOOL)isNotifyVibrateEnabled {
    if ([NSUserDefaults.standardUserDefaults objectForKey:kNotifyVibrate] == nil) {
        return YES;
    }
    return [NSUserDefaults.standardUserDefaults boolForKey:kNotifyVibrate];
}

+ (void)setNotifyVibrateEnabled:(BOOL)enabled {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kNotifyVibrate];
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (void)applyNotificationPreferences {
    [TUIConfig defaultConfig].enableCustomRing = [self isNotifySoundEnabled];
}

+ (NSString *)summarizeFriendAllowType:(NSInteger)allowType {
    if (allowType == V2TIM_FRIEND_NEED_CONFIRM) {
        return @"需要验证";
    }
    if (allowType == V2TIM_FRIEND_DENY_ANY) {
        return @"拒绝任何人";
    }
    return @"允许任何人";
}

+ (void)presentFriendAllowTypePickerFrom:(UIViewController *)vc
                             currentType:(NSInteger)allowType
                              completion:(void (^)(NSInteger))completion {
    if (!vc) {
        return;
    }
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"加好友方式"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSString *> *labels = @[ @"允许任何人", @"需要验证", @"拒绝任何人" ];
    NSArray<NSNumber *> *types = @[@(V2TIM_FRIEND_ALLOW_ANY), @(V2TIM_FRIEND_NEED_CONFIRM), @(V2TIM_FRIEND_DENY_ANY)];
    for (NSUInteger i = 0; i < labels.count; i++) {
        NSInteger t = types[i].integerValue;
        UIAlertActionStyle style = (t == allowType) ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault;
        [sheet addAction:[UIAlertAction actionWithTitle:labels[i] style:style handler:^(UIAlertAction *action) {
            V2TIMUserFullInfo *info = [[V2TIMUserFullInfo alloc] init];
            info.allowType = (V2TIMFriendAllowType)t;
            [[V2TIMManager sharedInstance] setSelfInfo:info succ:^{
                if (completion) {
                    completion(t);
                }
                UIAlertController *ok = [UIAlertController alertControllerWithTitle:@"提示"
                                                                            message:@"加好友方式已更新"
                                                                     preferredStyle:UIAlertControllerStyleAlert];
                [ok addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                [vc presentViewController:ok animated:YES completion:nil];
            } fail:^(int code, NSString *desc) {
                UIAlertController *err = [UIAlertController alertControllerWithTitle:@"提示"
                                                                             message:desc ?: @"设置失败"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
                [err addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                [vc presentViewController:err animated:YES completion:nil];
            }];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = vc.view;
        sheet.popoverPresentationController.sourceRect = CGRectMake(vc.view.bounds.size.width / 2, vc.view.bounds.size.height - 80, 1, 1);
    }
    [vc presentViewController:sheet animated:YES completion:nil];
}

@end
