#import "YLTMomentsApi.h"
#import "YLTMomentsNotificationHelper.h"
#import "YLTMomentImageUrls.h"
#import "YLTRuntimeApiBase.h"
#import "YLTAppConfig.h"
#import "YLTHTTPHelper.h"
#import "YLTLoginSession.h"
#import <ImSDK_Plus/ImSDK_Plus.h>

@implementation YLTMomentItem
@end

@implementation YLTMomentComment
@end

@implementation YLTMomentThread
@end

@implementation YLTMomentInteractionItem
@end

@implementation YLTMomentsApi

+ (NSString *)currentUserId {
    [[YLTLoginSession shared] loadFromDefaults];
    return [YLTLoginSession shared].userId ?: @"";
}

+ (NSMutableDictionary *)baseJsonFriendIds:(NSArray<NSString *> *)friendIds {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithObject:[self currentUserId] forKey:@"userid"];
    NSString *pwd = [YLTLoginSession shared].apiPassword;
    if (pwd.length) {
        json[@"password"] = pwd;
    }
    NSMutableArray *arr = [NSMutableArray array];
    for (NSString *fid in friendIds) {
        if (fid.length) {
            [arr addObject:fid];
        }
    }
    json[@"friend_ids"] = arr;
    return json;
}

+ (nullable NSDictionary *)postJson:(NSDictionary *)json script:(NSString *)script {
    for (NSString *url in [YLTRuntimeApiBase endpointCandidates:script]) {
        NSInteger code = 0;
        NSError *err = nil;
        NSData *data = [YLTHTTPHelper syncPOSTJson:json url:url apiKey:[YLTAppConfig userSigApiKey] statusCode:&code error:&err];
        if (err || code == 404) {
            continue;
        }
        if (code < 200 || code >= 300 || !data) {
            continue;
        }
        id o = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([o isKindOfClass:NSDictionary.class]) {
            return o;
        }
    }
    return nil;
}

+ (YLTMomentItem *)parseItem:(NSDictionary *)d {
    YLTMomentItem *m = [[YLTMomentItem alloc] init];
    m.momentId = [d[@"id"] longLongValue];
    m.authorUserId = d[@"authorUserId"] ?: d[@"userId"] ?: @"";
    m.content = d[@"content"] ?: @"";
    m.imageUrl = d[@"imageUrl"] ?: d[@"image_url"];
    m.imageUrls = [YLTMomentImageUrls parseToList:m.imageUrl];
    m.createdAt = d[@"createdAt"] ?: d[@"created_at"];
    m.likeCount = [d[@"likeCount"] intValue] ?: [d[@"like_count"] intValue];
    m.commentCount = [d[@"commentCount"] intValue] ?: [d[@"comment_count"] intValue];
    m.liked = [d[@"liked"] boolValue];
    return m;
}

+ (void)fetchFriendIds:(void (^)(NSArray<NSString *> *))callback {
    [[V2TIMManager sharedInstance] getFriendList:^(NSArray<V2TIMFriendInfo *> *infoList) {
        NSMutableArray *ids = [NSMutableArray array];
        for (V2TIMFriendInfo *f in infoList) {
            if (f.userID.length) {
                [ids addObject:f.userID];
            }
        }
        if (callback) {
            callback(ids);
        }
    } fail:^(int code, NSString *desc) {
        if (callback) {
            callback(@[]);
        }
    }];
}

+ (void)fetchFeedWithFriends:(NSArray<NSString *> *)friendIds callback:(void (^)(BOOL, NSArray<YLTMomentItem *> *, NSString *))callback {
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSDictionary *resp = [self postJson:[self baseJsonFriendIds:friendIds] script:@"moments_feed.php"];
        if (!resp || ![resp[@"ok"] boolValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{ callback(NO, @[], resp[@"error"] ?: @"加载失败"); });
            return;
        }
        NSArray *arr = resp[@"items"];
        NSMutableArray *items = [NSMutableArray array];
        if ([arr isKindOfClass:NSArray.class]) {
            for (id row in arr) {
                if ([row isKindOfClass:NSDictionary.class]) {
                    [items addObject:[self parseItem:row]];
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{ callback(YES, items, nil); });
    });
}

+ (void)publishContent:(NSString *)content imageUrl:(NSString *)imageUrl friendIds:(NSArray<NSString *> *)friendIds callback:(void (^)(BOOL, NSString *))callback {
    [self publishContent:content imageStorageField:imageUrl friendIds:friendIds callback:callback];
}

+ (void)publishContent:(NSString *)content imageStorageField:(NSString *)imageField friendIds:(NSArray<NSString *> *)friendIds callback:(void (^)(BOOL, NSString *))callback {
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableDictionary *req = [self baseJsonFriendIds:friendIds];
        req[@"content"] = content ?: @"";
        req[@"image_url"] = imageField ?: @"";
        NSDictionary *resp = [self postJson:req script:@"moments_publish.php"];
        BOOL ok = resp && [resp[@"ok"] boolValue];
        dispatch_async(dispatch_get_main_queue(), ^{ callback(ok, ok ? nil : (resp[@"error"] ?: @"发布失败")); });
    });
}

+ (void)toggleLikeMomentId:(int64_t)momentId friendIds:(NSArray<NSString *> *)friendIds callback:(void (^)(BOOL, BOOL, NSInteger, NSString *))callback {
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableDictionary *req = [self baseJsonFriendIds:friendIds];
        req[@"moment_id"] = @(momentId);
        NSDictionary *resp = [self postJson:req script:@"moments_like.php"];
        BOOL ok = resp && [resp[@"ok"] boolValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(ok, [resp[@"liked"] boolValue], [resp[@"likeCount"] integerValue], ok ? nil : (resp[@"error"] ?: @"操作失败"));
        });
    });
}

+ (void)fetchThreadMomentId:(int64_t)momentId friendIds:(NSArray<NSString *> *)friendIds callback:(void (^)(BOOL, YLTMomentThread *, NSString *))callback {
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableDictionary *req = [self baseJsonFriendIds:friendIds];
        req[@"moment_id"] = @(momentId);
        NSDictionary *resp = [self postJson:req script:@"moments_thread.php"];
        if (!resp || ![resp[@"ok"] boolValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{ callback(NO, nil, resp[@"error"] ?: @"加载失败"); });
            return;
        }
        YLTMomentThread *tr = [[YLTMomentThread alloc] init];
        tr.post = [self parseItem:resp[@"post"]];
        NSMutableArray *comments = [NSMutableArray array];
        NSArray *arr = resp[@"comments"];
        if ([arr isKindOfClass:NSArray.class]) {
            for (NSDictionary *c in arr) {
                if (![c isKindOfClass:NSDictionary.class]) {
                    continue;
                }
                YLTMomentComment *mc = [[YLTMomentComment alloc] init];
                mc.commentId = [c[@"id"] longLongValue];
                mc.authorUserId = c[@"authorUserId"] ?: @"";
                mc.parentCommentId = [c[@"parentCommentId"] longLongValue];
                mc.content = c[@"content"] ?: @"";
                mc.createdAt = c[@"createdAt"];
                [comments addObject:mc];
            }
        }
        tr.comments = comments;
        dispatch_async(dispatch_get_main_queue(), ^{ callback(YES, tr, nil); });
    });
}

+ (void)postCommentMomentId:(int64_t)momentId content:(NSString *)content parentCommentId:(int64_t)parentId friendIds:(NSArray<NSString *> *)friendIds callback:(void (^)(BOOL, NSString *))callback {
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableDictionary *req = [self baseJsonFriendIds:friendIds];
        req[@"moment_id"] = @(momentId);
        req[@"content"] = content ?: @"";
        if (parentId > 0) {
            req[@"parent_comment_id"] = @(parentId);
        }
        NSDictionary *resp = [self postJson:req script:@"moments_comment.php"];
        BOOL ok = resp && [resp[@"ok"] boolValue];
        dispatch_async(dispatch_get_main_queue(), ^{ callback(ok, ok ? nil : (resp[@"error"] ?: @"评论失败")); });
    });
}

+ (void)fetchCoverForUserId:(NSString *)targetUserId friendIds:(NSArray<NSString *> *)friendIds callback:(void (^)(BOOL, NSString *, NSString *))callback {
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableDictionary *req = [self baseJsonFriendIds:friendIds];
        req[@"target_user_id"] = targetUserId ?: @"";
        NSDictionary *resp = [self postJson:req script:@"moments_cover_get.php"];
        BOOL ok = resp && [resp[@"ok"] boolValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(ok, resp[@"coverUrl"], ok ? nil : (resp[@"error"] ?: @"获取封面失败"));
        });
    });
}

+ (void)setCoverImageUrl:(NSString *)imageUrl friendIds:(NSArray<NSString *> *)friendIds callback:(void (^)(BOOL, NSString *, NSString *))callback {
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableDictionary *req = [self baseJsonFriendIds:friendIds];
        req[@"image_url"] = imageUrl ?: @"";
        NSDictionary *resp = [self postJson:req script:@"moments_cover_set.php"];
        BOOL ok = resp && [resp[@"ok"] boolValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(ok, resp[@"coverUrl"], ok ? nil : (resp[@"error"] ?: @"设置封面失败"));
        });
    });
}

// legacy wrappers
+ (void)fetchFeedPage:(NSInteger)page pageSize:(NSInteger)pageSize callback:(void (^)(BOOL, NSArray<YLTMomentItem *> *, NSString *))callback {
    [self fetchFriendIds:^(NSArray<NSString *> *friendIds) {
        [self fetchFeedWithFriends:friendIds callback:callback];
    }];
}

+ (void)publishContent:(NSString *)content imageUrl:(NSString *)imageUrl callback:(void (^)(BOOL, NSString *))callback {
    [self fetchFriendIds:^(NSArray<NSString *> *friendIds) {
        [self publishContent:content imageUrl:imageUrl friendIds:friendIds callback:callback];
    }];
}

+ (void)toggleLikeMomentId:(int64_t)momentId callback:(void (^)(BOOL, NSString *))callback {
    [self fetchFriendIds:^(NSArray<NSString *> *friendIds) {
        [self toggleLikeMomentId:momentId friendIds:friendIds callback:^(BOOL ok, BOOL liked, NSInteger likeCount, NSString *error) {
            callback(ok, error);
        }];
    }];
}

+ (void)fetchNotificationCountsSinceMs:(long long)sinceMs callback:(void (^)(BOOL, YLTMomentsNotificationCounts *, NSString *))callback {
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableDictionary *req = [self baseJsonFriendIds:@[]];
        req[@"since_ms"] = @(sinceMs);
        NSDictionary *resp = [self postJson:req script:@"moments_notifications_count.php"];
        if (!resp || ![resp[@"ok"] boolValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{ callback(NO, nil, resp[@"error"] ?: @"加载失败"); });
            return;
        }
        YLTMomentsNotificationCounts *c = [[YLTMomentsNotificationCounts alloc] init];
        c.likeCount = [resp[@"like_count"] integerValue];
        c.commentCount = [resp[@"comment_count"] integerValue];
        c.total = [resp[@"count"] integerValue];
        if (c.total <= 0) {
            c.total = c.likeCount + c.commentCount;
        }
        dispatch_async(dispatch_get_main_queue(), ^{ callback(YES, c, nil); });
    });
}

+ (void)fetchNotificationsSinceMs:(long long)sinceMs callback:(void (^)(BOOL, NSArray<YLTMomentInteractionItem *> *, NSString *))callback {
    if (!callback) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableDictionary *req = [self baseJsonFriendIds:@[]];
        req[@"since_ms"] = @(sinceMs);
        NSDictionary *resp = [self postJson:req script:@"moments_notifications_list.php"];
        if (!resp || ![resp[@"ok"] boolValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{ callback(NO, @[], resp[@"error"] ?: @"加载失败"); });
            return;
        }
        NSMutableArray *items = [NSMutableArray array];
        NSArray *arr = resp[@"items"];
        if ([arr isKindOfClass:NSArray.class]) {
            for (NSDictionary *d in arr) {
                if (![d isKindOfClass:NSDictionary.class]) {
                    continue;
                }
                YLTMomentInteractionItem *it = [[YLTMomentInteractionItem alloc] init];
                it.type = d[@"type"] ?: @"";
                it.momentId = [d[@"moment_id"] longLongValue];
                it.actorUserId = d[@"actor_user_id"] ?: d[@"actorUserId"] ?: @"";
                it.content = d[@"content"];
                it.createdAt = d[@"created_at"] ?: d[@"createdAt"];
                [items addObject:it];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{ callback(YES, items, nil); });
    });
}

@end
