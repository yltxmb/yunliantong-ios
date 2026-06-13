#import "YLTQrPayload.h"

@implementation YLTQrPayload

+ (NSString *)buildPayloadForUserId:(NSString *)userId {
    if (userId.length == 0) {
        return @"";
    }
    NSString *enc = [userId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] ?: userId;
    return [NSString stringWithFormat:@"tencentimdemo://addfriend?userid=%@", enc];
}

+ (NSString *)parseUserIdFromQrText:(NSString *)raw {
    if (raw.length == 0) {
        return nil;
    }
    NSString *t = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSURLComponents *c = [NSURLComponents componentsWithString:t];
    if (c && [c.scheme caseInsensitiveCompare:@"tencentimdemo"] == NSOrderedSame && [c.host caseInsensitiveCompare:@"addfriend"] == NSOrderedSame) {
        for (NSURLQueryItem *item in c.queryItems) {
            if ([item.name isEqualToString:@"userid"] && item.value.length) {
                return item.value;
            }
        }
    }
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"^[a-zA-Z0-9_-]{1,128}$" options:0 error:nil];
    if ([re numberOfMatchesInString:t options:0 range:NSMakeRange(0, t.length)] > 0) {
        return t;
    }
    return nil;
}

@end
