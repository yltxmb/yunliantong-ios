#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTApiLinesFetcher : NSObject

+ (void)fetchWithCallback:(void (^)(BOOL ok, NSArray<NSString *> *lines, NSString * _Nullable error))callback;
+ (void)fetchUrl:(NSString *)url callback:(void (^)(BOOL ok, NSArray<NSString *> *lines, NSString * _Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
