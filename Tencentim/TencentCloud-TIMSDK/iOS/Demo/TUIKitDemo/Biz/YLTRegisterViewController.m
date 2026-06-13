#import "YLTRegisterViewController.h"
#import "YLTAuthApi.h"
#import "YLTMaintenanceGate.h"
#import "LoginController.h"

@interface YLTRegisterViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextField *phoneField;
@property (nonatomic, strong) UITextField *nicknameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextField *password2Field;
@property (nonatomic, strong) UITextField *answerField;
@property (nonatomic, strong) UIPickerView *questionPicker;
@property (nonatomic, strong) UIToolbar *pickerToolbar;
@property (nonatomic, copy) NSArray<NSString *> *questions;
@property (nonatomic, assign) BOOL questionsReady;
@end

@implementation YLTRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"注册";
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.97 blue:0.95 alpha:1];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.scrollView];

    CGFloat y = 20;
    CGFloat w = self.view.bounds.size.width - 40;
    self.phoneField = [self addField:@"11 位手机号" y:&y width:w];
    self.phoneField.keyboardType = UIKeyboardTypePhonePad;
    self.nicknameField = [self addField:@"昵称（2-20 字）" y:&y width:w];
    self.passwordField = [self addField:@"登录密码（6-128 位）" y:&y width:w];
    self.passwordField.secureTextEntry = YES;
    self.password2Field = [self addField:@"确认密码" y:&y width:w];
    self.password2Field.secureTextEntry = YES;

    UILabel *qLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, w, 20)];
    qLabel.text = @"密保问题";
    qLabel.font = [UIFont systemFontOfSize:13];
    qLabel.textColor = UIColor.grayColor;
    [self.scrollView addSubview:qLabel];
    y += 24;

    self.questionPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(20, y, w, 120)];
    self.questionPicker.delegate = self;
    self.questionPicker.dataSource = self;
    [self.scrollView addSubview:self.questionPicker];
    y += 130;

    self.answerField = [self addField:@"密保答案" y:&y width:w];

    UIButton *submit = [UIButton buttonWithType:UIButtonTypeSystem];
    submit.frame = CGRectMake(20, y + 10, w, 44);
    submit.backgroundColor = [UIColor colorWithRed:0.08 green:0.55 blue:0.24 alpha:1];
    [submit setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [submit setTitle:@"注册" forState:UIControlStateNormal];
    submit.layer.cornerRadius = 8;
    submit.enabled = NO;
    submit.tag = 9001;
    [submit addTarget:self action:@selector(onSubmit:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:submit];
    y += 60;
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, y);

    [YLTMaintenanceGate ensureNotMaintenanceThen:self onContinue:^{
        [YLTAuthApi fetchSecurityQuestions:^(BOOL ok, NSArray<NSString *> *questions, NSString *error) {
            if (!ok) {
                UIAlertController *a = [UIAlertController alertControllerWithTitle:@"提示" message:error preferredStyle:UIAlertControllerStyleAlert];
                [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:a animated:YES completion:nil];
                return;
            }
            self.questions = questions;
            self.questionsReady = YES;
            submit.enabled = YES;
            [self.questionPicker reloadAllComponents];
        }];
    }];
}

- (UITextField *)addField:(NSString *)placeholder y:(CGFloat *)y width:(CGFloat)w {
    UITextField *f = [[UITextField alloc] initWithFrame:CGRectMake(20, *y, w, 40)];
    f.borderStyle = UITextBorderStyleRoundedRect;
    f.placeholder = placeholder;
    f.delegate = self;
    [self.scrollView addSubview:f];
    *y += 52;
    return f;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.questions.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.questions[(NSUInteger)row];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)isValidPhone:(NSString *)phone {
    return phone.length == 11 && [[NSCharacterSet decimalDigitCharacterSet] isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:phone]];
}

- (void)onSubmit:(UIButton *)sender {
    if (!self.questionsReady || self.questions.count == 0) {
        return;
    }
    NSString *phone = [self.phoneField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *nick = [self.nicknameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *p1 = self.passwordField.text ?: @"";
    NSString *p2 = self.password2Field.text ?: @"";
    NSInteger qIdx = [self.questionPicker selectedRowInComponent:0];
    NSString *sq = self.questions[(NSUInteger)qIdx];
    NSString *sa = [self.answerField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (![self isValidPhone:phone]) {
        [self alert:@"请输入 11 位手机号"];
        return;
    }
    if (nick.length < 2 || nick.length > 20) {
        [self alert:@"昵称需 2-20 字"];
        return;
    }
    if (p1.length < 6 || p1.length > 128) {
        [self alert:@"密码需 6-128 位"];
        return;
    }
    if (![p1 isEqualToString:p2]) {
        [self alert:@"两次密码不一致"];
        return;
    }
    if (sa.length == 0) {
        [self alert:@"请填写密保答案"];
        return;
    }
    sender.enabled = NO;
    [YLTAuthApi registerPhone:phone nickname:nick password:p1 securityQuestion:sq securityAnswer:sa callback:^(BOOL ok, NSString *userId, NSString *txId, NSString *error) {
        sender.enabled = YES;
        if (!ok) {
            [self alert:error ?: @"注册失败"];
            return;
        }
        [self alert:@"注册成功，请登录"];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)alert:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"提示" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
