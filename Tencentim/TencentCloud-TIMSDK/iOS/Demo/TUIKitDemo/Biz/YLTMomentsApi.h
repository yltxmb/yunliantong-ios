#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTMomentItem : NSObject
@property (nonatomic, assign) int64_t momentId;
@property (nonatomic, copy) NSString *authorUserId;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy, nullable) NSString *imageUrl;
@property (nonatomic, copy) NSArray<NSString *> *imageUrls;
@property (nonatomic, copy, nullable) NSString *createdAt;
@property (nonatomic, assign) NSInteger likeCount;
@property (nonatomic, assign) NSInteger commentCount;
@property (nonatomic, assign) BOOL liked;
@end

@interface YLTMomentComment : NSObject
@property (nonatomic, assign) int64_t commentId;
@property (nonatomic, copy) NSString *authorUserId;
@property (nonatomic, assign) int64_t parentCommentId;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy, nullable) NSString *createdAt;
@end

@interface YLTMomentThread : NSObject
@property (nonatomic, strong) YLTMomentItem *post;
@property (nonatomic, copy) NSArray<YLTMomentComment *> *comments;
@end

@interface YLTMomentInteractionItem : NSObject
@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) int64_t momentId;
@property (nonatomic, copy) NSString *actorUserId;
@property (nonatomic, copy, nullable) NSString *content;
@property (nonatomic, copy, nullable) NSString *createdAt;
@end

@class YLTMomentsNotificationCounts;

@interface YLTMomentsApi : NSObject

+ (void)fetchFriendIds:(void (^)(NSArray<NSString *> *friendIds))callback;

+ (void)fetchFeedWithFriends:(NSArray<NSString *> *)friendIds
                    callback:(void (^)(BOOL ok, NSArray<YLTMomentItem *> *items, NSString * _Nullable error))callback;

+ (void)publishContent:(NSString *)content
              imageUrl:(nullable NSString *)imageUrl
             friendIds:(NSArray<NSString *> *)friendIds
              callback:(void (^)(BOOL ok, NSString * _Nullable error))callback;

+ (void)publishContent:(NSString *)content
     imageStorageField:(nullable NSString *)imageField
             friendIds:(NSArray<NSString *> *)friendIds
              callback:(void (^)(BOOL ok, NSString * _Nullable error))callback;

+ (void)toggleLikeMomentId:(int64_t)momentId
                 friendIds:(NSArray<NSString *> *)friendIds
                  callback:(void (^)(BOOL ok, BOOL liked, NSInteger likeCount, NSString * _Nullable error))callback;

+ (void)fetchThreadMomentId:(int64_t)momentId
                  friendIds:(NSArray<NSString *> *)friendIds
                   callback:(void (^)(BOOL ok, YLTMomentThread * _Nullable thread, NSString * _Nullable error))callback;

+ (void)postCommentMomentId:(int64_t)momentId
                    content:(NSString *)content
            parentCommentId:(int64_t)parentId
                  friendIds:(NSArray<NSString *> *)friendIds
                   callback:(void (^)(BOOL ok, NSString * _Nullable error))callback;

+ (void)fetchCoverForUserId:(NSString *)targetUserId
                  friendIds:(NSArray<NSString *> *)friendIds
                   callback:(void (^)(BOOL ok, NSString * _Nullable coverUrl, NSString * _Nullable error))callback;

+ (void)setCoverImageUrl:(NSString *)imageUrl
               friendIds:(NSArray<NSString *> *)friendIds
                callback:(void (^)(BOOL ok, NSString * _Nullable coverUrl, NSString * _Nullable error))callback;

+ (void)fetchNotificationCountsSinceMs:(long long)sinceMs
                              callback:(void (^)(BOOL ok, YLTMomentsNotificationCounts * _Nullable counts, NSString * _Nullable error))callback;

+ (void)fetchNotificationsSinceMs:(long long)sinceMs
                         callback:(void (^)(BOOL ok, NSArray<YLTMomentInteractionItem *> *items, NSString * _Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
