#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTMaintenanceGate : NSObject

+ (BOOL)syncFetchAndIsMaintenance;
+ (BOOL)isMaintenanceFromCache;
+ (NSString *)maintenanceMessageFromCache;
+ (void)ensureNotMaintenanceThen:(UIViewController *)vc onContinue:(dispatch_block_t)onContinue;

@end

NS_ASSUME_NONNULL_END
