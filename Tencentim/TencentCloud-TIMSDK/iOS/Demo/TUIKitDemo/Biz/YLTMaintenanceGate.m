#import "YLTMaintenanceGate.h"
#import "YLTPublicConfigRepository.h"
#import "YLTRuntimeApiBase.h"
#import "YLTMaintenanceViewController.h"

@implementation YLTMaintenanceGate

+ (BOOL)syncFetchAndIsMaintenance {
    if ([YLTRuntimeApiBase appPublicConfigUrl].length == 0) {
        return NO;
    }
    [YLTPublicConfigRepository syncFetch];
    return [self isMaintenanceFromCache];
}

+ (BOOL)isMaintenanceFromCache {
    return [YLTPublicConfigRepository isMaintenanceFromCache];
}

+ (NSString *)maintenanceMessageFromCache {
    return [YLTPublicConfigRepository maintenanceMessageFromCache];
}

+ (void)ensureNotMaintenanceThen:(UIViewController *)vc onContinue:(dispatch_block_t)onContinue {
    if (!vc || !onContinue) {
        return;
    }
    if ([YLTRuntimeApiBase appPublicConfigUrl].length == 0) {
        onContinue();
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        BOOL maint = [self syncFetchAndIsMaintenance];
        NSString *msg = [self maintenanceMessageFromCache];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (maint) {
                YLTMaintenanceViewController *m = [[YLTMaintenanceViewController alloc] initWithMessage:msg];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:m];
                nav.modalPresentationStyle = UIModalPresentationFullScreen;
                vc.view.window.rootViewController = nav;
                return;
            }
            onContinue();
        });
    });
}

@end
