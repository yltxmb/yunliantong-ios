#import "YLTAppConfig.h"

static NSString *YLTTrim(NSString *s) {
    return s ? [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : @"";
}

@implementation YLTAppConfig

+ (NSString *)defaultApiBase {
    NSString *base = YLTTrim([[NSBundle mainBundle] objectForInfoDictionaryKey:@"YLTApiBase"]);
    if (base.length == 0) {
        base = @"https://gl27.snbxj.cn";
    }
    while ([base hasSuffix:@"/"]) {
        base = [base substringToIndex:base.length - 1];
    }
    return base;
}

+ (NSString *)userSigApiUrl {
    NSString *url = YLTTrim([[NSBundle mainBundle] objectForInfoDictionaryKey:@"YLTUserSigApiUrl"]);
    if (url.length == 0) {
        url = [NSString stringWithFormat:@"%@/api/usersig.php", [self defaultApiBase]];
    }
    return url;
}

+ (NSString *)userSigApiKey {
    return YLTTrim([[NSBundle mainBundle] objectForInfoDictionaryKey:@"YLTUserSigApiKey"]);
}

+ (NSString *)appPublicConfigUrl {
    NSString *url = YLTTrim([[NSBundle mainBundle] objectForInfoDictionaryKey:@"YLTAppPublicConfigUrl"]);
    if (url.length == 0) {
        url = [NSString stringWithFormat:@"%@/api/app_public_config.php", [self defaultApiBase]];
    }
    return url;
}

+ (NSString *)momentImageUploadUrl {
    NSString *url = YLTTrim([[NSBundle mainBundle] objectForInfoDictionaryKey:@"YLTMomentImageUploadUrl"]);
    if (url.length == 0) {
        url = [NSString stringWithFormat:@"%@/api/upload_image.php", [self defaultApiBase]];
    }
    return url;
}

+ (NSString *)apiLinesUrl {
    NSString *url = YLTTrim([[NSBundle mainBundle] objectForInfoDictionaryKey:@"YLTApiLinesUrl"]);
    if (url.length == 0) {
        url = @"https://glxdz-1381796032.cos.accelerate.myqcloud.com/gl27.txt";
    }
    return url;
}

@end
