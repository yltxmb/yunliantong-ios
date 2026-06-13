#import "YLTAuthApi.h"
#import "YLTRuntimeApiBase.h"
#import "YLTAppConfig.h"
#import "YLTHTTPHelper.h"

@implementation YLTAuthApi

+ (BOOL)isConfigured {
    return [YLTRuntimeApiBase appApiBase].length > 0;
}

+ (void)fetchSecurityQuestions:(void (^)(BOOL, NSArray<NSString *> *, NSString *))callback {
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *base = [YLTRuntimeApiBase appApiBase];
        NSArray *urls = @[
            [NSString stringWithFormat:@"%@/api/security_questions", base],
            [NSString stringWithFormat:@"%@/api/security_questions.php", base],
        ];
        for (NSString *url in urls) {
            NSError *err = nil;
            NSData *data = [YLTHTTPHelper syncGETUrl:url apiKey:[YLTAppConfig userSigApiKey] error:&err];
            if (!data) {
                continue;
            }
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (![json isKindOfClass:NSDictionary.class] || ![json[@"ok"] boolValue]) {
                continue;
            }
            NSArray *arr = json[@"questions"];
            NSMutableArray *list = [NSMutableArray array];
            if ([arr isKindOfClass:NSArray.class]) {
                for (id q in arr) {
                    if ([q isKindOfClass:NSString.class] && [(NSString *)q length]) {
                        [list addObject:q];
                    }
                }
            }
            if (list.count == 0) {
                continue;
            }
            dispatch_async(dispatch_get_main_queue(), ^{ callback(YES, list, nil); });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{ callback(NO, @[], @"无法加载密保问题"); });
    });
}

+ (void)postScript:(NSString *)script json:(NSDictionary *)json callback:(void (^)(NSDictionary * _Nullable resp, NSString * _Nullable error))callback {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        for (NSString *url in [YLTRuntimeApiBase endpointCandidates:script]) {
            NSInteger code = 0;
            NSError *err = nil;
            NSData *data = [YLTHTTPHelper syncPOSTJson:json url:url apiKey:[YLTAppConfig userSigApiKey] statusCode:&code error:&err];
            if (code == 404) {
                continue;
            }
            if (err || code < 200 || code >= 300 || !data) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(nil, err.localizedDescription ?: [NSString stringWithFormat:@"HTTP %ld", (long)code]);
                });
                return;
            }
            NSDictionary *o = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{ callback(o, nil); });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{ callback(nil, @"接口不可用"); });
    });
}

+ (void)registerPhone:(NSString *)phone nickname:(NSString *)nickname password:(NSString *)password securityQuestion:(NSString *)question securityAnswer:(NSString *)answer callback:(void (^)(BOOL, NSString *, NSString *, NSString *))callback {
    if (!callback) {
        return;
    }
    NSDictionary *json = @{
        @"phone": phone ?: @"",
        @"nickname": nickname ?: @"",
        @"password": password ?: @"",
        @"security_question": question ?: @"",
        @"security_answer": answer ?: @""
    };
    [self postScript:@"register.php" json:json callback:^(NSDictionary *resp, NSString *error) {
        if (error) {
            callback(NO, nil, nil, error);
            return;
        }
        if (![resp[@"ok"] boolValue]) {
            callback(NO, nil, nil, resp[@"error"] ?: @"注册失败");
            return;
        }
        NSString *uid = resp[@"userId"] ?: resp[@"userID"];
        NSString *txId = resp[@"txId"] ?: resp[@"tx_id"];
        callback(YES, uid, txId, nil);
    }];
}

+ (void)resetPasswordPhone:(NSString *)phone securityQuestion:(NSString *)question securityAnswer:(NSString *)answer newPassword:(NSString *)newPassword callback:(void (^)(BOOL, NSString *))callback {
    if (!callback) {
        return;
    }
    NSDictionary *json = @{
        @"phone": phone ?: @"",
        @"security_question": question ?: @"",
        @"security_answer": answer ?: @"",
        @"new_password": newPassword ?: @""
    };
    [self postScript:@"reset_password.php" json:json callback:^(NSDictionary *resp, NSString *error) {
        if (error) {
            callback(NO, error);
            return;
        }
        callback([resp[@"ok"] boolValue], [resp[@"ok"] boolValue] ? nil : (resp[@"error"] ?: @"重置失败"));
    }];
}

@end
