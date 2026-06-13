#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTQrPayload : NSObject
+ (NSString *)buildPayloadForUserId:(NSString *)userId;
+ (nullable NSString *)parseUserIdFromQrText:(NSString *)raw;
@end

NS_ASSUME_NONNULL_END
