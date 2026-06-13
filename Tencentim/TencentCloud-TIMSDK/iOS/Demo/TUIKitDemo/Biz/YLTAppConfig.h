#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 云链通 iOS 业务配置（与 Android local.properties / BuildConfig 对齐，可在 CI 用 xcconfig 覆盖）
@interface YLTAppConfig : NSObject

+ (NSString *)defaultApiBase;
+ (NSString *)userSigApiUrl;
+ (NSString *)userSigApiKey;
+ (NSString *)appPublicConfigUrl;
+ (NSString *)momentImageUploadUrl;
+ (NSString *)apiLinesUrl;

@end

NS_ASSUME_NONNULL_END
