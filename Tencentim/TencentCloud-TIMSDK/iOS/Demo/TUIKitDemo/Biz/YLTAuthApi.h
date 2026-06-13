#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTAuthApi : NSObject

+ (BOOL)isConfigured;

+ (void)fetchSecurityQuestions:(void (^)(BOOL ok, NSArray<NSString *> *questions, NSString * _Nullable error))callback;

+ (void)registerPhone:(NSString *)phone
             nickname:(NSString *)nickname
             password:(NSString *)password
     securityQuestion:(NSString *)question
       securityAnswer:(NSString *)answer
             callback:(void (^)(BOOL ok, NSString * _Nullable userId, NSString * _Nullable txId, NSString * _Nullable error))callback;

+ (void)resetPasswordPhone:(NSString *)phone
          securityQuestion:(NSString *)question
            securityAnswer:(NSString *)answer
               newPassword:(NSString *)newPassword
                  callback:(void (^)(BOOL ok, NSString * _Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
