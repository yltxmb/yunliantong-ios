#import "YLTHTTPHelper.h"

@implementation YLTHTTPHelper

+ (NSData *)syncDataTask:(NSURLRequest *)request statusCode:(NSInteger *)statusCode error:(NSError **)error {
    __block NSData *result = nil;
    __block NSHTTPURLResponse *httpResp = nil;
    __block NSError *reqErr = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *r, NSError *e) {
        result = data;
        httpResp = (NSHTTPURLResponse *)r;
        reqErr = e;
        dispatch_semaphore_signal(sem);
    }] resume];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    if (statusCode) {
        *statusCode = httpResp.statusCode;
    }
    if (error) {
        *error = reqErr;
    }
    return result;
}

+ (NSData *)syncPOSTJson:(NSDictionary *)json url:(NSString *)urlStr apiKey:(NSString *)apiKey statusCode:(NSInteger *)statusCode error:(NSError **)error {
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) {
        return nil;
    }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    if (apiKey.length) {
        [req setValue:apiKey forHTTPHeaderField:@"X-Api-Key"];
    }
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    return [self syncDataTask:req statusCode:statusCode error:error];
}

+ (NSData *)syncGETUrl:(NSString *)urlStr error:(NSError **)error {
    return [self syncGETUrl:urlStr apiKey:nil error:error];
}

+ (NSData *)syncGETUrl:(NSString *)urlStr apiKey:(NSString *)apiKey error:(NSError **)error {
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) {
        return nil;
    }
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:12];
    req.HTTPMethod = @"GET";
    if (apiKey.length) {
        [req setValue:apiKey forHTTPHeaderField:@"X-Api-Key"];
    }
    return [self syncDataTask:req statusCode:NULL error:error];
}

@end
