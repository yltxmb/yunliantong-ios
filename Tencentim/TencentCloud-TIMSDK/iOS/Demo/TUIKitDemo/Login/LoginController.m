//
//  LoginController.m
//  云链通 — 手机号 + 密码 → usersig.php → IM 登录
//

#import "LoginController.h"
#import "AppDelegate.h"
#import "YLTServerUserSigFetcher.h"
#import "YLTLoginSession.h"
#import "YLTMaintenanceGate.h"
#import "YLTApiLinesFetcher.h"
#import "YLTRuntimeApiBase.h"
#import "YLTRegisterViewController.h"
#import "YLTForgotPasswordViewController.h"
#import "TUIThemeManager.h"
#import "TUIUtil.h"
#import <TUICore/TUITool.h>

@interface LoginController ()
@property (weak, nonatomic) IBOutlet UITextField *user;
@property (weak, nonatomic) IBOutlet UIImageView *logView;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UILabel *lineLabel;
@property (nonatomic, strong) UIButton *linkRegister;
@property (nonatomic, strong) UIButton *linkForgot;
@property (nonatomic, assign) BOOL loginInFlight;
@end

@implementation LoginController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.97 blue:0.95 alpha:1];
    self.logView.image = TUIDemoDynamicImage(@"public_login_logo_img", [UIImage imageNamed:@"public_login_logo"]);
    self.loginButton.backgroundColor = [UIColor colorWithRed:0.08 green:0.55 blue:0.24 alpha:1];
    [self.loginButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.loginButton setTitle:@"登录" forState:UIControlStateNormal];
    self.loginButton.layer.cornerRadius = 8;
    self.user.placeholder = @"中国大陆 11 位手机号";
    self.user.keyboardType = UIKeyboardTypePhonePad;
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)]];

    self.passwordField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.passwordField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordField.placeholder = @"登录密码";
    self.passwordField.secureTextEntry = YES;
    self.passwordField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.passwordField];

    self.lineLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.lineLabel.font = [UIFont systemFontOfSize:13];
    self.lineLabel.textColor = [UIColor grayColor];
    self.lineLabel.userInteractionEnabled = YES;
    self.lineLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.lineLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPickLine)]];
    [self.view addSubview:self.lineLabel];

    self.linkRegister = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.linkRegister setTitle:@"注册账号" forState:UIControlStateNormal];
    [self.linkRegister addTarget:self action:@selector(onRegister) forControlEvents:UIControlEventTouchUpInside];
    self.linkRegister.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.linkRegister];

    self.linkForgot = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.linkForgot setTitle:@"忘记密码" forState:UIControlStateNormal];
    [self.linkForgot addTarget:self action:@selector(onForgot) forControlEvents:UIControlEventTouchUpInside];
    self.linkForgot.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.linkForgot];

    [NSLayoutConstraint activateConstraints:@[
        [self.passwordField.leadingAnchor constraintEqualToAnchor:self.user.leadingAnchor],
        [self.passwordField.trailingAnchor constraintEqualToAnchor:self.user.trailingAnchor],
        [self.passwordField.topAnchor constraintEqualToAnchor:self.user.bottomAnchor constant:16],
        [self.passwordField.heightAnchor constraintEqualToConstant:34],
        [self.lineLabel.leadingAnchor constraintEqualToAnchor:self.user.leadingAnchor],
        [self.lineLabel.topAnchor constraintEqualToAnchor:self.passwordField.bottomAnchor constant:12],
        [self.linkRegister.leadingAnchor constraintEqualToAnchor:self.user.leadingAnchor],
        [self.linkRegister.topAnchor constraintEqualToAnchor:self.lineLabel.bottomAnchor constant:8],
        [self.linkForgot.trailingAnchor constraintEqualToAnchor:self.user.trailingAnchor],
        [self.linkForgot.centerYAnchor constraintEqualToAnchor:self.linkRegister.centerYAnchor],
        [self.loginButton.topAnchor constraintEqualToAnchor:self.linkRegister.bottomAnchor constant:16],
    ]];
    self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;

    [YLTRuntimeApiBase initStorage];
    [self refreshLineLabel];
    [YLTApiLinesFetcher fetchWithCallback:^(BOOL ok, NSArray<NSString *> *lines, NSString *error) {
        if (ok && lines.count) {
            [YLTRuntimeApiBase persistRemoteLines:lines];
            [self refreshLineLabel];
        }
    }];

    [YLTMaintenanceGate ensureNotMaintenanceThen:self onContinue:^{
        NSString *phone = [NSUserDefaults.standardUserDefaults stringForKey:@"YLT_Phone"];
        if (phone.length) {
            self.user.text = phone;
        }
    }];
}

- (void)refreshLineLabel {
    NSArray *lines = [YLTRuntimeApiBase persistedLineBases];
    if (lines.count == 0) {
        self.lineLabel.text = [NSString stringWithFormat:@"线路：默认 (%@)", [YLTRuntimeApiBase appApiBase]];
    } else {
        NSInteger idx = [YLTRuntimeApiBase selectedLineIndex];
        self.lineLabel.text = [NSString stringWithFormat:@"线路 %ld：%@", (long)(idx + 1), lines[(NSUInteger)idx]];
    }
}

- (void)onPickLine {
    NSArray *lines = [YLTRuntimeApiBase persistedLineBases];
    if (lines.count == 0) {
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"线路" message:@"正在拉取线路列表…" preferredStyle:UIAlertControllerStyleAlert];
        [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:a animated:YES completion:nil];
        return;
    }
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择线路" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL *stop) {
        [sheet addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"线路 %lu：%@", (unsigned long)(idx + 1), line] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [YLTRuntimeApiBase setSelectedLineIndex:(NSInteger)idx];
            [self refreshLineLabel];
        }]];
    }];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)onTap {
    [self.view endEditing:YES];
}

- (IBAction)login:(id)sender {
    [self.view endEditing:YES];
    if (self.loginInFlight) {
        return;
    }
    NSString *phone = [self.user.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *password = self.passwordField.text ?: @"";
    if (phone.length != 11) {
        [self alertText:@"请输入 11 位手机号"];
        return;
    }
    if (password.length == 0) {
        [self alertText:@"请输入密码"];
        return;
    }
    self.loginInFlight = YES;
    self.loginButton.enabled = NO;
    [TUITool makeToastActivity:TUICSToastPositionCenter];
    [YLTServerUserSigFetcher fetchUserId:phone password:password callback:^(BOOL ok, uint32_t sdkAppId, NSString *userSig, NSString *imUserId, NSString *txId, NSString *error) {
        self.loginInFlight = NO;
        self.loginButton.enabled = YES;
        if (!ok) {
            [TUITool hideToastActivity];
            [self alertText:error ?: @"登录失败"];
            return;
        }
        [[YLTLoginSession shared] saveWithSDKAppId:sdkAppId userId:imUserId userSig:userSig phone:phone txId:txId password:password];
        AppDelegate *delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
        [delegate loginSDK:imUserId userSig:userSig succ:^{
            [TUITool hideToastActivity];
        } fail:^(int code, NSString *msg) {
            [TUITool hideToastActivity];
            [self alertText:[NSString stringWithFormat:@"IM 登录失败 (%d): %@", code, msg ?: @""]];
        }];
    }];
}

- (void)onRegister {
    YLTRegisterViewController *vc = [[YLTRegisterViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onForgot {
    YLTForgotPasswordViewController *vc = [[YLTForgotPasswordViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)alertText:(NSString *)str {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:str message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
