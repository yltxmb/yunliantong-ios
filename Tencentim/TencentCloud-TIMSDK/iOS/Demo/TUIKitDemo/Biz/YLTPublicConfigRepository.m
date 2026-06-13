#import "YLTPublicConfigRepository.h"
#import "YLTRuntimeApiBase.h"
#import "YLTAppConfig.h"
#import "YLTHTTPHelper.h"

static NSString *const kPublicConfigJson = @"YLT_PublicConfigJson";
static NSString *const kAnnouncementSeenRev = @"YLT_AnnouncementSeenRev";
static NSString *const kAnnouncementDeferRev = @"YLT_AnnouncementDeferRev";
static NSString *const kAnnouncementDeferAtMs = @"YLT_AnnouncementDeferAtMs";
static const NSTimeInterval kDeferCooldownSec = 30 * 60;

@implementation YLTPublicConfigRepository

+ (NSArray<NSString *> *)candidateUrls {
    NSString *raw = [YLTRuntimeApiBase appPublicConfigUrl];
    if (raw.length == 0) {
        return @[];
    }
    NSMutableArray *set = [NSMutableArray arrayWithObject:raw];
    if ([raw hasSuffix:@".php"]) {
        [set addObject:[raw substringToIndex:raw.length - 4]];
    } else {
        [set addObject:[raw stringByAppendingString:@".php"]];
    }
    return set;
}

+ (nullable NSDictionary *)fetchRemote {
    for (NSString *urlStr in [self candidateUrls]) {
        NSInteger code = 0;
        NSError *err = nil;
        NSData *data = [YLTHTTPHelper syncPOSTJson:@{} url:urlStr apiKey:[YLTAppConfig userSigApiKey] statusCode:&code error:&err];
        if (err || code < 200 || code >= 300 || !data) {
            continue;
        }
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (![json isKindOfClass:NSDictionary.class] || ![json[@"ok"] boolValue]) {
            continue;
        }
        return (NSDictionary *)json;
    }
    return nil;
}

+ (void)persist:(NSDictionary *)o {
    NSData *d = [NSJSONSerialization dataWithJSONObject:o options:0 error:nil];
    if (!d) {
        return;
    }
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    [NSUserDefaults.standardUserDefaults setObject:s forKey:kPublicConfigJson];
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (nullable NSDictionary *)cachedConfigObject {
    NSString *s = [NSUserDefaults.standardUserDefaults stringForKey:kPublicConfigJson];
    if (s.length == 0) {
        return nil;
    }
    NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
    return [json isKindOfClass:NSDictionary.class] ? json : nil;
}

+ (BOOL)syncFetch {
    NSDictionary *o = [self fetchRemote];
    if (!o) {
        return NO;
    }
    [self persist:o];
    return YES;
}

+ (void)refreshInBackground:(void (^)(BOOL))callback {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        BOOL ok = [self syncFetch];
        if (callback) {
            dispatch_async(dispatch_get_main_queue(), ^{ callback(ok); });
        }
    });
}

+ (BOOL)optBool:(NSDictionary *)o keys:(NSArray<NSString *> *)keys defaultVal:(BOOL)def {
    for (NSString *k in keys) {
        id v = o[k];
        if (v != nil) {
            if ([v isKindOfClass:NSNumber.class]) {
                return [(NSNumber *)v boolValue];
            }
            if ([v isKindOfClass:NSString.class]) {
                NSString *s = [(NSString *)v lowercaseString];
                return [s isEqualToString:@"1"] || [s isEqualToString:@"true"] || [s isEqualToString:@"yes"];
            }
        }
    }
    return def;
}

+ (NSString *)optString:(NSDictionary *)o keys:(NSArray<NSString *> *)keys {
    for (NSString *k in keys) {
        id v = o[k];
        if ([v isKindOfClass:NSString.class] && [(NSString *)v length]) {
            return v;
        }
    }
    return @"";
}

+ (BOOL)isMaintenanceFromCache {
    NSDictionary *o = [self cachedConfigObject];
    if (!o) {
        return NO;
    }
    return [self optBool:o keys:@[@"maintenanceMode", @"app_maintenance_enabled", @"maintenance_mode"] defaultVal:NO];
}

+ (NSString *)maintenanceMessageFromCache {
    NSDictionary *o = [self cachedConfigObject];
    NSString *m = [self optString:o keys:@[@"maintenanceMessage", @"app_maintenance_message", @"maintenance_message"]];
    return m.length ? m : @"系统维护中，请稍后再试。";
}

+ (NSString *)announcementTitleFromCache {
    NSDictionary *o = [self cachedConfigObject];
    return [self optString:o keys:@[@"announcementTitle", @"app_announcement_title", @"announcement_title"]];
}

+ (NSString *)announcementBodyFromCache {
    NSDictionary *o = [self cachedConfigObject];
    NSString *html = [self announcementHtmlFromCache];
    if (html.length) {
        return html;
    }
    return [self optString:o keys:@[@"announcementBody", @"app_announcement_body", @"announcement_body", @"announcementContent", @"announcement_content"]];
}

+ (NSString *)announcementHtmlFromCache {
    NSDictionary *o = [self cachedConfigObject];
    return [self optString:o keys:@[@"announcementHtml", @"announcement_html", @"app_announcement_html"]];
}

+ (BOOL)isAnnouncementEnabledFromCache {
    NSDictionary *o = [self cachedConfigObject];
    if (!o) {
        return NO;
    }
    return [self optBool:o keys:@[@"announcementEnabled", @"announcement_enabled", @"app_announcement_enabled"] defaultVal:NO];
}

+ (NSString *)announcementRevFromCache {
    NSDictionary *o = [self cachedConfigObject];
    NSString *title = [self announcementTitleFromCache];
    NSString *html = [self announcementHtmlFromCache];
    if (html.length == 0) {
        html = [self optString:o keys:@[@"announcementBody", @"app_announcement_body", @"announcement_body"]];
    }
    NSString *rev = [self optString:o keys:@[@"announcementRev", @"announcement_rev", @"app_announcement_rev", @"announcementId", @"announcement_id"]];
    if (rev.length) {
        return rev;
    }
    return [NSString stringWithFormat:@"h%lu", (unsigned long)[[NSString stringWithFormat:@"%@\n%@", title ?: @"", html ?: @""] hash]];
}

+ (BOOL)shouldShowAnnouncement {
    NSDictionary *o = [self cachedConfigObject];
    if (!o || ![self isAnnouncementEnabledFromCache]) {
        return NO;
    }
    NSString *title = [self announcementTitleFromCache];
    NSString *html = [self announcementHtmlFromCache];
    NSString *body = [self announcementBodyFromCache];
    if (title.length == 0 && html.length == 0 && body.length == 0) {
        return NO;
    }
    NSString *rev = [self announcementRevFromCache];
    NSString *seen = [NSUserDefaults.standardUserDefaults stringForKey:kAnnouncementSeenRev];
    if ([rev isEqualToString:seen]) {
        return NO;
    }
    NSString *deferRev = [NSUserDefaults.standardUserDefaults stringForKey:kAnnouncementDeferRev];
    NSTimeInterval deferAt = [NSUserDefaults.standardUserDefaults doubleForKey:kAnnouncementDeferAtMs];
    if ([rev isEqualToString:deferRev] && [[NSDate date] timeIntervalSince1970] - deferAt < kDeferCooldownSec) {
        return NO;
    }
    return YES;
}

+ (void)markAnnouncementShown {
    NSString *rev = [self announcementRevFromCache];
    if (rev.length == 0) {
        return;
    }
    [NSUserDefaults.standardUserDefaults setObject:rev forKey:kAnnouncementSeenRev];
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (void)deferAnnouncement {
    NSString *rev = [self announcementRevFromCache];
    if (rev.length == 0) {
        return;
    }
    [NSUserDefaults.standardUserDefaults setObject:rev forKey:kAnnouncementDeferRev];
    [NSUserDefaults.standardUserDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kAnnouncementDeferAtMs];
    [NSUserDefaults.standardUserDefaults synchronize];
}

@end
