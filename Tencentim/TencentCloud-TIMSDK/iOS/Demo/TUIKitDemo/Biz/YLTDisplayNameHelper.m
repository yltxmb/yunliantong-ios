#import "YLTDisplayNameHelper.h"
#import <ImSDK_Plus/ImSDK_Plus.h>

static NSMutableDictionary<NSString *, NSString *> *gLabels;

@implementation YLTDisplayNameHelper

+ (void)ensureCache {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gLabels = [NSMutableDictionary dictionary];
    });
}

+ (NSString *)labelForUserId:(NSString *)userId {
    if (userId.length == 0) {
        return @"";
    }
    [self ensureCache];
    NSString *cached = gLabels[userId];
    return cached.length ? cached : userId;
}

+ (void)invalidateAll {
    [self ensureCache];
    [gLabels removeAllObjects];
}

+ (void)prefetchUserIds:(NSArray<NSString *> *)userIds completion:(dispatch_block_t)completion {
    if (userIds.count == 0) {
        if (completion) {
            completion();
        }
        return;
    }
    NSMutableSet *missing = [NSMutableSet set];
    [self ensureCache];
    for (NSString *uid in userIds) {
        if (uid.length && !gLabels[uid]) {
            [missing addObject:uid];
        }
    }
    if (missing.count == 0) {
        if (completion) {
            completion();
        }
        return;
    }
    NSArray *ids = missing.allObjects;
    [[V2TIMManager sharedInstance] getFriendsInfo:ids succ:^(NSArray<V2TIMFriendInfoResult *> *resultList) {
        NSMutableSet *stillMissing = [missing mutableCopy];
        for (V2TIMFriendInfoResult *r in resultList) {
            if (r.resultCode != 0 || !r.friendInfo) {
                continue;
            }
            NSString *uid = r.friendInfo.userID;
            if (!uid.length) {
                continue;
            }
            NSString *label = r.friendInfo.friendRemark;
            if (!label.length) {
                label = r.friendInfo.userFullInfo.nickName;
            }
            if (label.length) {
                gLabels[uid] = label;
            }
            [stillMissing removeObject:uid];
        }
        if (stillMissing.count == 0) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), completion);
            }
            return;
        }
        [[V2TIMManager sharedInstance] getUsersInfo:stillMissing.allObjects succ:^(NSArray<V2TIMUserFullInfo *> *infoList) {
            for (V2TIMUserFullInfo *info in infoList) {
                if (!info.userID.length) {
                    continue;
                }
                NSString *label = info.nickName.length ? info.nickName : info.userID;
                gLabels[info.userID] = label;
            }
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), completion);
            }
        } fail:^(int code, NSString *desc) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), completion);
            }
        }];
    } fail:^(int code, NSString *desc) {
        [[V2TIMManager sharedInstance] getUsersInfo:ids succ:^(NSArray<V2TIMUserFullInfo *> *infoList) {
            for (V2TIMUserFullInfo *info in infoList) {
                if (!info.userID.length) {
                    continue;
                }
                gLabels[info.userID] = info.nickName.length ? info.nickName : info.userID;
            }
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), completion);
            }
        } fail:^(int code2, NSString *desc2) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), completion);
            }
        }];
    }];
}

@end
