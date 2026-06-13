#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTPublicConfigRepository : NSObject

+ (void)refreshInBackground:(nullable void (^)(BOOL ok))callback;
+ (BOOL)syncFetch;
+ (nullable NSDictionary *)fetchRemote;
+ (void)persist:(NSDictionary *)config;
+ (nullable NSDictionary *)cachedConfigObject;
+ (BOOL)isMaintenanceFromCache;
+ (NSString *)maintenanceMessageFromCache;
+ (nullable NSString *)announcementTitleFromCache;
+ (nullable NSString *)announcementBodyFromCache;
+ (nullable NSString *)announcementHtmlFromCache;
+ (NSString *)announcementRevFromCache;
+ (BOOL)isAnnouncementEnabledFromCache;
+ (BOOL)shouldShowAnnouncement;
+ (void)markAnnouncementShown;
+ (void)deferAnnouncement;

@end

NS_ASSUME_NONNULL_END
