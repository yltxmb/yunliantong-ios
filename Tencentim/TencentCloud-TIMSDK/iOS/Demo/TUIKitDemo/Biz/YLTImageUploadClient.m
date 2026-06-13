#import "YLTImageUploadClient.h"
#import "YLTRuntimeApiBase.h"
#import "YLTAppConfig.h"
#import "YLTLoginSession.h"

@implementation YLTImageUploadClient

+ (BOOL)isConfigured {
    return [YLTRuntimeApiBase momentImageUploadUrl].length > 0 || [YLTRuntimeApiBase appApiBase].length > 0;
}

+ (void)uploadImage:(UIImage *)image callback:(void (^)(BOOL, NSString *, NSString *))callback {
    if (!callback || !image) {
        return;
    }
    [[YLTLoginSession shared] loadFromDefaults];
    NSData *jpeg = UIImageJPEGRepresentation(image, 0.85);
    if (!jpeg) {
        callback(NO, nil, @"图片无效");
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray *urls = [YLTRuntimeApiBase endpointCandidates:@"upload_image.php"];
        NSString *lastErr = nil;
        for (NSString *urlStr in urls) {
            NSURL *url = [NSURL URLWithString:urlStr];
            if (!url) {
                continue;
            }
            NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
            NSMutableData *body = [NSMutableData data];
            void (^appendField)(NSString *, NSString *) = ^(NSString *name, NSString *value) {
                [body appendData:[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", boundary, name, value] dataUsingEncoding:NSUTF8StringEncoding]];
            };
            appendField(@"userid", [YLTLoginSession shared].userId ?: @"");
            NSString *pwd = [YLTLoginSession shared].apiPassword;
            if (pwd.length) {
                appendField(@"password", pwd);
            } else if ([YLTLoginSession shared].userSig.length) {
                appendField(@"usersig", [YLTLoginSession shared].userSig);
            }
            [body appendData:[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:jpeg];
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
            req.HTTPMethod = @"POST";
            [req setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
            NSString *key = [YLTAppConfig userSigApiKey];
            if (key.length) {
                [req setValue:key forHTTPHeaderField:@"X-Api-Key"];
            }
            req.HTTPBody = body;

            __block NSData *result = nil;
            __block NSHTTPURLResponse *httpResp = nil;
            __block NSError *reqErr = nil;
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            [[NSURLSession.sharedSession dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *r, NSError *e) {
                result = data;
                httpResp = (NSHTTPURLResponse *)r;
                reqErr = e;
                dispatch_semaphore_signal(sem);
            }] resume];
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

            if (reqErr) {
                lastErr = reqErr.localizedDescription;
                continue;
            }
            if (httpResp.statusCode == 404) {
                lastErr = @"HTTP 404";
                continue;
            }
            if (httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
                lastErr = [NSString stringWithFormat:@"HTTP %ld", (long)httpResp.statusCode];
                continue;
            }
            NSDictionary *o = [NSJSONSerialization JSONObjectWithData:result options:0 error:nil];
            NSString *imgUrl = o[@"url"] ?: o[@"imageUrl"];
            if (imgUrl.length) {
                dispatch_async(dispatch_get_main_queue(), ^{ callback(YES, imgUrl, nil); });
                return;
            }
            if ([o[@"ok"] boolValue]) {
                lastErr = @"missing url";
                continue;
            }
            lastErr = o[@"error"] ?: @"upload failed";
        }
        dispatch_async(dispatch_get_main_queue(), ^{ callback(NO, nil, lastErr ?: @"上传失败"); });
    });
}

@end
