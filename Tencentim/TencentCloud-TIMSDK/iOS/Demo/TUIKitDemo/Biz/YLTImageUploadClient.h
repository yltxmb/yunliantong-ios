#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTImageUploadClient : NSObject

+ (BOOL)isConfigured;

+ (void)uploadImage:(UIImage *)image
           callback:(void (^)(BOOL ok, NSString * _Nullable imageUrl, NSString * _Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
