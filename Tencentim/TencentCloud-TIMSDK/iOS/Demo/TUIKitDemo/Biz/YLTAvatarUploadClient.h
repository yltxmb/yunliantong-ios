#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTAvatarUploadClient : NSObject

+ (void)uploadAvatarImage:(UIImage *)image callback:(void (^)(BOOL ok, NSString * _Nullable avatarUrl, NSString * _Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
