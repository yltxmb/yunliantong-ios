#import "YLTLoginSession.h"
#import "TCLoginModel.h"

static NSString *const kYLTSDKAppId = @"YLT_SDKAppId";
static NSString *const kYLTUserId = @"YLT_UserId";
static NSString *const kYLTUserSig = @"YLT_UserSig";
static NSString *const kYLTPhone = @"YLT_Phone";
static NSString *const kYLTTxId = @"YLT_TxId";
static NSString *const kYLTApiPassword = @"YLT_ApiPassword";

@interface YLTLoginSession ()
@property (nonatomic, assign, readwrite) uint32_t sdkAppId;
@property (nonatomic, copy, readwrite, nullable) NSString *userId;
@property (nonatomic, copy, readwrite, nullable) NSString *userSig;
@property (nonatomic, copy, readwrite, nullable) NSString *phone;
@property (nonatomic, copy, readwrite, nullable) NSString *txId;
@property (nonatomic, copy, readwrite, nullable) NSString *apiPassword;
@end

@implementation YLTLoginSession

+ (instancetype)shared {
    static YLTLoginSession *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[YLTLoginSession alloc] init]; });
    return s;
}

+ (uint32_t)currentSDKAppId {
    [[YLTLoginSession shared] loadFromDefaults];
    return [YLTLoginSession shared].sdkAppId;
}

- (void)loadFromDefaults {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    self.sdkAppId = (uint32_t)[d integerForKey:kYLTSDKAppId];
    self.userId = [d stringForKey:kYLTUserId];
    self.userSig = [d stringForKey:kYLTUserSig];
    self.phone = [d stringForKey:kYLTPhone];
    self.txId = [d stringForKey:kYLTTxId];
    self.apiPassword = [d stringForKey:kYLTApiPassword];
}

- (void)saveWithSDKAppId:(uint32_t)sdkAppId
                  userId:(NSString *)userId
                 userSig:(NSString *)userSig
                   phone:(NSString *)phone
                    txId:(NSString *)txId
                password:(nullable NSString *)password {
    self.sdkAppId = sdkAppId;
    self.userId = userId;
    self.userSig = userSig;
    self.phone = phone;
    self.txId = txId;
    self.apiPassword = password;
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    [d setInteger:sdkAppId forKey:kYLTSDKAppId];
    [d setObject:userId forKey:kYLTUserId];
    [d setObject:userSig forKey:kYLTUserSig];
    if (phone.length) {
        [d setObject:phone forKey:kYLTPhone];
    }
    if (txId.length) {
        [d setObject:txId forKey:kYLTTxId];
    }
    if (password.length) {
        [d setObject:password forKey:kYLTApiPassword];
    }
    [d synchronize];
    [[TCLoginModel sharedInstance] saveLoginedInfoWithUserID:userId userSig:userSig];
    [[TCLoginModel sharedInstance] setIsDirectlyLoginSDK:YES];
}

- (void)saveWithSDKAppId:(uint32_t)sdkAppId userId:(NSString *)userId userSig:(NSString *)userSig phone:(NSString *)phone txId:(NSString *)txId {
    [self saveWithSDKAppId:sdkAppId userId:userId userSig:userSig phone:phone txId:txId password:nil];
}

- (void)clear {
    self.sdkAppId = 0;
    self.userId = nil;
    self.userSig = nil;
    self.phone = nil;
    self.txId = nil;
    self.apiPassword = nil;
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    [d removeObjectForKey:kYLTSDKAppId];
    [d removeObjectForKey:kYLTUserId];
    [d removeObjectForKey:kYLTUserSig];
    [d removeObjectForKey:kYLTPhone];
    [d removeObjectForKey:kYLTTxId];
    [d removeObjectForKey:kYLTApiPassword];
    [d synchronize];
}

@end
