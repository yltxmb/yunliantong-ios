#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 朋友圈 image_url：单图裸 URL；多图为 JSON 数组字符串。 */
@interface YLTMomentImageUrls : NSObject

+ (NSArray<NSString *> *)parseToList:(nullable NSString *)imageField;
+ (NSString *)toStorageField:(NSArray<NSString *> *)urls;

@end

NS_ASSUME_NONNULL_END
