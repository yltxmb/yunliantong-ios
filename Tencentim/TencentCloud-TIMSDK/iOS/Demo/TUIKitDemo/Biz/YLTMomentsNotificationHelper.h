#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const YLTMomentsBadgeRefreshNotification;

@interface YLTMomentsNotificationCounts : NSObject
@property (nonatomic, assign) NSInteger total;
@property (nonatomic, assign) NSInteger likeCount;
@property (nonatomic, assign) NSInteger commentCount;
@end

@interface YLTMomentsNotificationHelper : NSObject

+ (long long)lastSeenMs;
+ (void)markMomentsFeedSeenNow;
+ (void)markSeenAndRefreshBadges;
+ (void)refreshDiscoverBadgeAsync;

@end

NS_ASSUME_NONNULL_END
