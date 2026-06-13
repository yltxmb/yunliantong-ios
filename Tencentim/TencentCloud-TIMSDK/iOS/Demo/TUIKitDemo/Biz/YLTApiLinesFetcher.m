#import "YLTApiLinesFetcher.h"
#import "YLTAppConfig.h"
#import "YLTHTTPHelper.h"

@implementation YLTApiLinesFetcher

+ (void)fetchWithCallback:(void (^)(BOOL, NSArray<NSString *> *, NSString *))callback {
    [self fetchUrl:[YLTAppConfig apiLinesUrl] callback:callback];
}

+ (void)fetchUrl:(NSString *)url callback:(void (^)(BOOL, NSArray<NSString *> *, NSString *))callback {
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSError *err = nil;
        NSData *data = [YLTHTTPHelper syncGETUrl:url error:&err];
        if (err || !data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(NO, @[], err.localizedDescription ?: @"network error");
            });
            return;
        }
        NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
        NSMutableArray *lines = [NSMutableArray array];
        for (NSString *part in [body componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
            NSString *t = [part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (t.length) {
                [lines addObject:t];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(YES, lines, nil);
        });
    });
}

@end
