#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 多线路 API 根地址（与 Android DemoRuntimeApiBase 一致）
@interface YLTRuntimeApiBase : NSObject

+ (void)initStorage;
+ (NSString *)normalizeBaseUrl:(NSString *)raw;
+ (NSArray<NSString *> *)persistedLineBases;
+ (NSInteger)selectedLineIndex;
+ (void)setSelectedLineIndex:(NSInteger)index;
+ (void)persistRemoteLines:(NSArray<NSString *> *)rawLines;
+ (BOOL)hasRemoteLineOverride;
+ (nullable NSString *)currentLineBaseOrNull;
+ (NSString *)appApiBase;
+ (NSString *)userSigApiUrl;
+ (NSString *)appPublicConfigUrl;
+ (NSString *)momentImageUploadUrl;
+ (NSArray<NSString *> *)endpointCandidates:(NSString *)scriptPhp;

@end

NS_ASSUME_NONNULL_END
