#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTHTTPHelper : NSObject

+ (nullable NSData *)syncPOSTJson:(NSDictionary *)json
                              url:(NSString *)urlStr
                         apiKey:(nullable NSString *)apiKey
                     statusCode:(NSInteger *)statusCode
                          error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSData *)syncGETUrl:(NSString *)urlStr error:(NSError * _Nullable * _Nullable)error;

+ (nullable NSData *)syncGETUrl:(NSString *)urlStr apiKey:(nullable NSString *)apiKey error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
