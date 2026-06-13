#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTServerUserSigFetcher : NSObject

+ (BOOL)isApiConfigured;

+ (void)fetchUserId:(NSString *)userId
           password:(nullable NSString *)password
           callback:(void (^)(BOOL ok, uint32_t sdkAppId, NSString * _Nullable userSig, NSString * _Nullable imUserId, NSString * _Nullable txId, NSString * _Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
