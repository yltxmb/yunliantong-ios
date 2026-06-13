#import "YLTProfileViewController.h"
#import "YLTMyQrCodeViewController.h"
#import "YLTSelfDetailViewController.h"
#import "YLTForgotPasswordViewController.h"
#import "YLTLegalDocumentViewController.h"
#import "YLTLoginSession.h"
#import "YLTUserSettingsHelper.h"
#import "AppDelegate.h"
#import "TCLoginModel.h"
#import <TUICore/TUILogin.h>
#import <ImSDK_Plus/ImSDK_Plus.h>
#import "TUIBlackListController.h"
#import <SDWebImage/UIImageView+WebCache.h>

typedef NS_ENUM(NSInteger, YLTProfileSettingsRow) {
    YLTProfileSettingsRowFriendAllow = 0,
    YLTProfileSettingsRowNotifySound,
    YLTProfileSettingsRowNotifyVibrate,
};

typedef NS_ENUM(NSInteger, YLTProfileRow) {
    YLTProfileRowMyQr = 0,
    YLTProfileRowBlacklist,
    YLTProfileRowChangePassword,
    YLTProfileRowUserAgreement,
    YLTProfileRowPrivacy,
    YLTProfileRowLogout,
};

@interface YLTProfileViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSString *> *menuTitles;
@property (nonatomic, copy) NSArray<NSString *> *settingsTitles;
@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, copy) NSString *faceUrl;
@property (nonatomic, assign) NSInteger friendAllowType;
@end

@implementation YLTProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我";
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.settingsTitles = @[ @"加好友方式", @"通知声音", @"通知振动" ];
    self.menuTitles = @[ @"我的二维码", @"黑名单", @"修改密码", @"用户使用协议", @"用户隐私政策", @"退出登录" ];
    self.friendAllowType = V2TIM_FRIEND_ALLOW_ANY;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self loadSelfInfo];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadSelfInfo];
}

- (void)loadSelfInfo {
    NSString *uid = [TUILogin getUserID];
    if (uid.length == 0) {
        return;
    }
    [[V2TIMManager sharedInstance] getUsersInfo:@[uid] succ:^(NSArray<V2TIMUserFullInfo *> *infoList) {
        V2TIMUserFullInfo *info = infoList.firstObject;
        self.nickName = info.nickName ?: uid;
        self.faceUrl = info.faceURL;
        self.friendAllowType = info.allowType;
        [self.tableView reloadData];
    } fail:^(int code, NSString *desc) {
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 1 ? @"设置" : nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    if (section == 1) {
        return self.settingsTitles.count;
    }
    return self.menuTitles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 ? 88 : 48;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *cid = @"header";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cid];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        [[YLTLoginSession shared] loadFromDefaults];
        cell.textLabel.text = self.nickName ?: [YLTLoginSession shared].userId;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:18];
        NSString *tx = [YLTLoginSession shared].txId;
        cell.detailTextLabel.text = tx.length ? [NSString stringWithFormat:@"账号 %@", tx] : @"";
        if (self.faceUrl.length) {
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:self.faceUrl] placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
        } else {
            cell.imageView.image = [UIImage systemImageNamed:@"person.circle.fill"];
        }
        return cell;
    }
    if (indexPath.section == 1) {
        if ((YLTProfileSettingsRow)indexPath.row == YLTProfileSettingsRowFriendAllow) {
            static NSString *cid = @"settingsNav";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cid];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            cell.textLabel.text = self.settingsTitles[(NSUInteger)indexPath.row];
            cell.detailTextLabel.text = [YLTUserSettingsHelper summarizeFriendAllowType:self.friendAllowType];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryView = nil;
            return cell;
        }
        static NSString *cid = @"settingsSwitch";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cid];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textLabel.text = self.settingsTitles[(NSUInteger)indexPath.row];
        UISwitch *sw = [[UISwitch alloc] init];
        if ((YLTProfileSettingsRow)indexPath.row == YLTProfileSettingsRowNotifySound) {
            sw.on = [YLTUserSettingsHelper isNotifySoundEnabled];
            sw.tag = 1;
        } else {
            sw.on = [YLTUserSettingsHelper isNotifyVibrateEnabled];
            sw.tag = 2;
        }
        [sw addTarget:self action:@selector(onSettingSwitch:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
        return cell;
    }
    static NSString *cid = @"menu";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cid];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = self.menuTitles[(NSUInteger)indexPath.row];
    if (indexPath.row == YLTProfileRowLogout) {
        cell.textLabel.textColor = [UIColor systemRedColor];
    } else {
        cell.textLabel.textColor = UIColor.labelColor;
    }
    return cell;
}

- (void)onSettingSwitch:(UISwitch *)sender {
    if (sender.tag == 1) {
        [YLTUserSettingsHelper setNotifySoundEnabled:sender.isOn];
    } else {
        [YLTUserSettingsHelper setNotifyVibrateEnabled:sender.isOn];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        YLTSelfDetailViewController *vc = [[YLTSelfDetailViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    if (indexPath.section == 1) {
        if ((YLTProfileSettingsRow)indexPath.row == YLTProfileSettingsRowFriendAllow) {
            __weak typeof(self) weakSelf = self;
            [YLTUserSettingsHelper presentFriendAllowTypePickerFrom:self
                                                        currentType:self.friendAllowType
                                                         completion:^(NSInteger newType) {
                weakSelf.friendAllowType = newType;
                [weakSelf.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:YLTProfileSettingsRowFriendAllow inSection:1] ]
                                          withRowAnimation:UITableViewRowAnimationNone];
            }];
        }
        return;
    }
    switch ((YLTProfileRow)indexPath.row) {
        case YLTProfileRowMyQr: {
            YLTMyQrCodeViewController *vc = [[YLTMyQrCodeViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case YLTProfileRowBlacklist: {
            TUIBlackListController *vc = [[TUIBlackListController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case YLTProfileRowChangePassword: {
            YLTForgotPasswordViewController *vc = [[YLTForgotPasswordViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case YLTProfileRowUserAgreement: {
            YLTLegalDocumentViewController *vc = [[YLTLegalDocumentViewController alloc] initWithKind:YLTLegalDocumentKindUserAgreement];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case YLTProfileRowPrivacy: {
            YLTLegalDocumentViewController *vc = [[YLTLegalDocumentViewController alloc] initWithKind:YLTLegalDocumentKindPrivacy];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case YLTProfileRowLogout:
            [self confirmLogout];
            break;
    }
}

- (void)confirmLogout {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认退出登录？" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [TUILogin logout:^{
            [[TCLoginModel sharedInstance] clearLoginedInfo];
            [[YLTLoginSession shared] clear];
            AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
            app.window.rootViewController = [app getLoginController];
        } fail:^(int code, NSString *msg) {
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
