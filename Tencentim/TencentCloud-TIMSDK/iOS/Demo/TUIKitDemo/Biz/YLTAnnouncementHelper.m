#import "YLTAnnouncementHelper.h"
#import "YLTPublicConfigRepository.h"
#import "YLTAnnouncementViewController.h"

static NSTimeInterval sLastShowUptime;

@implementation YLTAnnouncementHelper

+ (void)maybeShowFrom:(UIViewController *)vc {
    if (!vc || ![YLTPublicConfigRepository shouldShowAnnouncement]) {
        return;
    }
    NSTimeInterval now = [NSProcessInfo processInfo].systemUptime;
    if (now - sLastShowUptime < 0.8) {
        return;
    }
    sLastShowUptime = now;
    if (vc.presentedViewController) {
        return;
    }
    NSString *title = [YLTPublicConfigRepository announcementTitleFromCache];
    NSString *html = [YLTPublicConfigRepository announcementHtmlFromCache];
    if (html.length == 0) {
        html = [YLTPublicConfigRepository announcementBodyFromCache];
    }
    YLTAnnouncementViewController *ann = [[YLTAnnouncementViewController alloc] init];
    ann.titleText = title.length ? title : @"公告";
    ann.htmlBody = html ?: @"";
    ann.announcementRev = [YLTPublicConfigRepository announcementRevFromCache];
    ann.modalPresentationStyle = UIModalPresentationOverFullScreen;
    ann.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    ann.onConfirm = ^{
        [YLTPublicConfigRepository markAnnouncementShown];
    };
    ann.onDefer = ^{
        [YLTPublicConfigRepository deferAnnouncement];
    };
    [vc presentViewController:ann animated:YES completion:nil];
}

@end
