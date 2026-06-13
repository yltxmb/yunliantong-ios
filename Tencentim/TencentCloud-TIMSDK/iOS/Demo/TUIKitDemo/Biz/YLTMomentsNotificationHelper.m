#import "YLTMomentsNotificationHelper.h"
#import "YLTMomentsApi.h"
#import "YLTLoginSession.h"

NSNotificationName const YLTMomentsBadgeRefreshNotification = @"YLTMomentsBadgeRefreshNotification";

static NSString *const kLastSeenKey = @"YLT_MomentsLastSeenMs";

@implementation YLTMomentsNotificationCounts
@end

@implementation YLTMomentsNotificationHelper

+ (long long)lastSeenMs {
    NSNumber *v = [NSUserDefaults.standardUserDefaults objectForKey:kLastSeenKey];
    if (!v) {
        long long now = (long long)(NSDate.date.timeIntervalSince1970 * 1000.0);
        [NSUserDefaults.standardUserDefaults setObject:@(now) forKey:kLastSeenKey];
        return now;
    }
    return v.longLongValue;
}

+ (void)markMomentsFeedSeenNow {
    long long now = (long long)(NSDate.date.timeIntervalSince1970 * 1000.0);
    [NSUserDefaults.standardUserDefaults setObject:@(now) forKey:kLastSeenKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (void)markSeenAndRefreshBadges {
    [self markMomentsFeedSeenNow];
    [self refreshDiscoverBadgeAsync];
}

+ (void)refreshDiscoverBadgeAsync {
    [[YLTLoginSession shared] loadFromDefaults];
    if ([YLTLoginSession shared].userId.length == 0) {
        return;
    }
    long long since = [self lastSeenMs];
    [YLTMomentsApi fetchNotificationCountsSinceMs:since callback:^(BOOL ok, YLTMomentsNotificationCounts *counts, NSString *error) {
        if (!ok || !counts) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:YLTMomentsBadgeRefreshNotification
                                                                object:nil
                                                              userInfo:@{
                @"total": @(counts.total),
                @"likeCount": @(counts.likeCount),
                @"commentCount": @(counts.commentCount),
            }];
        });
    }];
}

@end
