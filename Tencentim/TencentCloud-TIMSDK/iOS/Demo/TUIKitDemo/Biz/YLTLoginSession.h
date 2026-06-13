#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define YLT_SDKAPPID [YLTLoginSession currentSDKAppId]

/// 持久化 IM 登录会话：sdkAppId / userId / userSig 均由 usersig.php 下发
@interface YLTLoginSession : NSObject

@property (nonatomic, assign, readonly) uint32_t sdkAppId;
@property (nonatomic, copy, readonly, nullable) NSString *userId;
@property (nonatomic, copy, readonly, nullable) NSString *userSig;
@property (nonatomic, copy, readonly, nullable) NSString *phone;
@property (nonatomic, copy, readonly, nullable) NSString *txId;
@property (nonatomic, copy, readonly, nullable) NSString *apiPassword;

+ (instancetype)shared;

+ (uint32_t)currentSDKAppId;

- (void)saveWithSDKAppId:(uint32_t)sdkAppId
                  userId:(NSString *)userId
                 userSig:(NSString *)userSig
                   phone:(nullable NSString *)phone
                    txId:(nullable NSString *)txId
                password:(nullable NSString *)password;

- (void)saveWithSDKAppId:(uint32_t)sdkAppId
                  userId:(NSString *)userId
                 userSig:(NSString *)userSig
                   phone:(nullable NSString *)phone
                    txId:(nullable NSString *)txId;

- (void)loadFromDefaults;
- (void)clear;

@end

NS_ASSUME_NONNULL_END
