#import "YLTServerUserSigFetcher.h"
#import "YLTRuntimeApiBase.h"
#import "YLTAppConfig.h"
#import "YLTHTTPHelper.h"

@implementation YLTServerUserSigFetcher

+ (BOOL)isApiConfigured {
    return [YLTRuntimeApiBase userSigApiUrl].length > 0;
}

+ (void)fetchUserId:(NSString *)userId
           password:(NSString *)password
           callback:(void (^)(BOOL, uint32_t, NSString *, NSString *, NSString *, NSString *))callback {
    if (!callback) {
        return;
    }
    if (userId.length == 0) {
        callback(NO, 0, nil, nil, nil, @"请输入手机号");
        return;
    }
    if (![self isApiConfigured]) {
        callback(NO, 0, nil, nil, nil, @"未配置 usersig 接口");
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableDictionary *json = [NSMutableDictionary dictionaryWithObject:userId forKey:@"userid"];
        if (password.length) {
            json[@"password"] = password;
        }
        NSArray *urls = [YLTRuntimeApiBase endpointCandidates:@"usersig.php"];
        NSString *lastError = nil;
        for (NSString *urlStr in urls) {
            NSInteger code = 0;
            NSError *err = nil;
            NSData *data = [YLTHTTPHelper syncPOSTJson:json url:urlStr apiKey:[YLTAppConfig userSigApiKey] statusCode:&code error:&err];
            if (err) {
                lastError = err.localizedDescription;
                continue;
            }
            if (code == 404) {
                lastError = [NSString stringWithFormat:@"HTTP 404 %@", urlStr];
                continue;
            }
            NSString *respBody = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
            if (code < 200 || code >= 300) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(NO, 0, nil, nil, nil, [NSString stringWithFormat:@"HTTP %ld: %@", (long)code, respBody]);
                });
                return;
            }
            NSDictionary *o = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if (![o[@"ok"] boolValue]) {
                NSString *msg = o[@"error"] ?: @"unknown";
                NSString *detail = o[@"detail"];
                if ([detail isKindOfClass:NSString.class] && detail.length) {
                    msg = [NSString stringWithFormat:@"%@ %@", msg, detail];
                }
                dispatch_async(dispatch_get_main_queue(), ^{ callback(NO, 0, nil, nil, nil, msg); });
                return;
            }
            uint32_t sdkAppId = (uint32_t)[o[@"SDKAppID"] intValue];
            if (sdkAppId == 0) {
                sdkAppId = (uint32_t)[o[@"sdkAppId"] intValue];
            }
            NSString *userSig = o[@"userSig"];
            if (sdkAppId == 0 || userSig.length == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(NO, 0, nil, nil, nil, @"invalid response: missing sdkAppId or userSig");
                });
                return;
            }
            NSString *resolvedId = o[@"userId"] ?: o[@"userID"];
            if (resolvedId.length == 0) {
                resolvedId = userId;
            }
            NSString *txId = o[@"txId"] ?: o[@"tx_id"];
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(YES, sdkAppId, userSig, resolvedId, txId, nil);
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(NO, 0, nil, nil, nil, lastError ?: @"all endpoints failed");
        });
    });
}

@end
