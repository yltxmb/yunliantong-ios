#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 朋友圈 / 互动通知展示名：好友备注 > IM 昵称 > userId
@interface YLTDisplayNameHelper : NSObject

+ (NSString *)labelForUserId:(NSString *)userId;

+ (void)prefetchUserIds:(NSArray<NSString *> *)userIds completion:(nullable dispatch_block_t)completion;

+ (void)invalidateAll;

@end

NS_ASSUME_NONNULL_END
