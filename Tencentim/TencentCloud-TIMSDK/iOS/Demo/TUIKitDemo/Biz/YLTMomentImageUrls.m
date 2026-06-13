#import "YLTMomentImageUrls.h"

@implementation YLTMomentImageUrls

+ (NSArray<NSString *> *)parseToList:(NSString *)imageField {
    if (imageField.length == 0) {
        return @[];
    }
    NSString *s = [imageField stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![s hasPrefix:@"["]) {
        return @[ s ];
    }
    NSData *data = [s dataUsingEncoding:NSUTF8StringEncoding];
    id json = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    if (![json isKindOfClass:NSArray.class]) {
        return @[ s ];
    }
    NSMutableArray *out = [NSMutableArray array];
    for (id item in (NSArray *)json) {
        if ([item isKindOfClass:NSString.class] && [(NSString *)item length]) {
            [out addObject:[(NSString *)item stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
    }
    return out;
}

+ (NSString *)toStorageField:(NSArray<NSString *> *)urls {
    if (urls.count == 0) {
        return @"";
    }
    NSMutableArray *clean = [NSMutableArray array];
    for (NSString *u in urls) {
        if (u.length) {
            [clean addObject:[u stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
    }
    if (clean.count == 0) {
        return @"";
    }
    if (clean.count == 1) {
        return clean.firstObject;
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:clean options:0 error:nil];
    return data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
}

@end
