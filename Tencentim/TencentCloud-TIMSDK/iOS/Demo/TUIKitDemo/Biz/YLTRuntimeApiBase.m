#import "YLTRuntimeApiBase.h"
#import "YLTAppConfig.h"

static NSString *const kPref = @"ylt_multi_line_api";
static NSString *const kLines = @"line_bases_nl";
static NSString *const kIndex = @"line_selected";

@implementation YLTRuntimeApiBase

+ (void)initStorage {
    // NSUserDefaults 无需额外 init
}

+ (NSString *)normalizeBaseUrl:(NSString *)raw {
    if (!raw) {
        return @"";
    }
    NSString *t = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    while ([t hasSuffix:@"/"]) {
        t = [t substringToIndex:t.length - 1];
    }
    return t;
}

+ (NSArray<NSString *> *)parseLinesBlob:(NSString *)blob {
    if (blob.length == 0) {
        return @[];
    }
    NSMutableArray *out = [NSMutableArray array];
    for (NSString *part in [blob componentsSeparatedByString:@"\n"]) {
        NSString *t = [self normalizeBaseUrl:part];
        if (t.length) {
            [out addObject:t];
        }
    }
    return out;
}

+ (NSArray<NSString *> *)persistedLineBases {
    NSString *blob = [NSUserDefaults.standardUserDefaults stringForKey:kLines];
    return [self parseLinesBlob:blob ?: @""];
}

+ (NSInteger)selectedLineIndex {
    return MAX(0, [NSUserDefaults.standardUserDefaults integerForKey:kIndex]);
}

+ (void)setSelectedLineIndex:(NSInteger)index {
    NSArray *lines = [self persistedLineBases];
    if (lines.count == 0) {
        return;
    }
    NSInteger i = MAX(0, MIN(index, (NSInteger)lines.count - 1));
    [NSUserDefaults.standardUserDefaults setInteger:i forKey:kIndex];
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (void)persistRemoteLines:(NSArray<NSString *> *)rawLines {
    NSMutableArray *norm = [NSMutableArray array];
    for (NSString *s in rawLines) {
        NSString *t = [self normalizeBaseUrl:s];
        if (t.length) {
            [norm addObject:t];
        }
    }
    NSInteger prev = [self selectedLineIndex];
    [NSUserDefaults.standardUserDefaults setObject:[norm componentsJoinedByString:@"\n"] forKey:kLines];
    if (norm.count == 0) {
        [NSUserDefaults.standardUserDefaults setInteger:0 forKey:kIndex];
    } else {
        NSInteger ni = prev < (NSInteger)norm.count ? prev : 0;
        [NSUserDefaults.standardUserDefaults setInteger:ni forKey:kIndex];
    }
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (BOOL)hasRemoteLineOverride {
    return [self persistedLineBases].count > 0;
}

+ (NSString *)currentLineBaseOrNull {
    NSArray *lines = [self persistedLineBases];
    if (lines.count == 0) {
        return nil;
    }
    NSInteger i = [self selectedLineIndex];
    if (i >= (NSInteger)lines.count) {
        i = 0;
    }
    return lines[(NSUInteger)i];
}

+ (NSString *)appApiBase {
    NSString *line = [self currentLineBaseOrNull];
    if (line.length) {
        return line;
    }
    return [YLTAppConfig defaultApiBase];
}

+ (NSString *)userSigApiUrl {
    NSString *line = [self currentLineBaseOrNull];
    if (line.length) {
        return [NSString stringWithFormat:@"%@/api/usersig.php", line];
    }
    return [YLTAppConfig userSigApiUrl];
}

+ (NSString *)appPublicConfigUrl {
    NSString *line = [self currentLineBaseOrNull];
    if (line.length) {
        return [NSString stringWithFormat:@"%@/api/app_public_config.php", line];
    }
    return [YLTAppConfig appPublicConfigUrl];
}

+ (NSString *)momentImageUploadUrl {
    NSString *line = [self currentLineBaseOrNull];
    if (line.length) {
        return [NSString stringWithFormat:@"%@/api/upload_image.php", line];
    }
    return [YLTAppConfig momentImageUploadUrl];
}

+ (void)addUrlIfNew:(NSMutableArray<NSString *> *)urls url:(NSString *)url {
    if (url.length == 0) {
        return;
    }
    for (NSString *u in urls) {
        if ([u isEqualToString:url]) {
            return;
        }
    }
    [urls addObject:url];
}

+ (NSArray<NSString *> *)endpointCandidates:(NSString *)scriptPhp {
    NSMutableArray<NSString *> *urls = [NSMutableArray array];
    NSString *base = [self appApiBase];
    if (base.length && scriptPhp.length) {
        [self addUrlIfNew:urls url:[NSString stringWithFormat:@"%@/api/%@", base, scriptPhp]];
        if ([scriptPhp hasSuffix:@".php"]) {
            NSString *noPhp = [scriptPhp substringToIndex:scriptPhp.length - 4];
            [self addUrlIfNew:urls url:[NSString stringWithFormat:@"%@/api/%@", base, noPhp]];
        } else {
            [self addUrlIfNew:urls url:[NSString stringWithFormat:@"%@/api/%@.php", base, scriptPhp]];
        }
    }
    NSString *fallback = [YLTAppConfig userSigApiUrl];
    if ([scriptPhp isEqualToString:@"usersig.php"] && fallback.length) {
        [self addUrlIfNew:urls url:fallback];
        if ([fallback hasSuffix:@".php"]) {
            [self addUrlIfNew:urls url:[fallback substringToIndex:fallback.length - 4]];
        }
    }
    return urls;
}

@end
