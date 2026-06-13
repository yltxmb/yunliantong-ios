#import "YLTAddFriendNavigator.h"
#import "YLTAddFriendViewController.h"
#import "YLTScanViewController.h"
#import "YLTLoginSession.h"
#import <TUICore/TUILogin.h>

@implementation YLTAddFriendNavigator

+ (void)presentScanFromViewController:(UIViewController *)fromVC {
    if (!fromVC) {
        return;
    }
    YLTScanViewController *vc = [[YLTScanViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [fromVC presentViewController:nav animated:YES completion:nil];
}

+ (void)openAddFriendFromViewController:(UIViewController *)fromVC userId:(NSString *)userId {
    if (!fromVC || userId.length == 0) {
        return;
    }
    NSString *selfId = [TUILogin getUserID];
    if (selfId.length && [selfId isEqualToString:userId]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"不能添加自己为好友" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [fromVC presentViewController:alert animated:YES completion:nil];
        return;
    }
    YLTAddFriendViewController *vc = [[YLTAddFriendViewController alloc] initWithUserId:userId];
    if (fromVC.navigationController) {
        [fromVC.navigationController pushViewController:vc animated:YES];
    } else {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [fromVC presentViewController:nav animated:YES completion:nil];
    }
}

@end
