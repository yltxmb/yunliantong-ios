#import "YLTForgotPasswordViewController.h"
#import "YLTAuthApi.h"
#import "YLTMaintenanceGate.h"

@interface YLTForgotPasswordViewController () <UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextField *phoneField;
@property (nonatomic, strong) UITextField *answerField;
@property (nonatomic, strong) UITextField *newPassField;
@property (nonatomic, strong) UITextField *confirmField;
@property (nonatomic, strong) UIPickerView *questionPicker;
@property (nonatomic, copy) NSArray<NSString *> *questions;
@property (nonatomic, assign) BOOL questionsReady;
@end

@implementation YLTForgotPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"修改密码";
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.97 blue:0.95 alpha:1];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];

    CGFloat y = 20;
    CGFloat w = self.view.bounds.size.width - 40;
    self.phoneField = [self addField:@"11 位手机号" y:&y width:w];
    self.phoneField.keyboardType = UIKeyboardTypePhonePad;

    UILabel *qLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, w, 20)];
    qLabel.text = @"密保问题（须与注册时一致）";
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
    self.newPassField = [self addField:@"新密码" y:&y width:w];
    self.newPassField.secureTextEntry = YES;
    self.confirmField = [self addField:@"确认新密码" y:&y width:w];
    self.confirmField.secureTextEntry = YES;

    UIButton *submit = [UIButton buttonWithType:UIButtonTypeSystem];
    submit.frame = CGRectMake(20, y + 10, w, 44);
    submit.backgroundColor = [UIColor colorWithRed:0.08 green:0.55 blue:0.24 alpha:1];
    [submit setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [submit setTitle:@"重置密码" forState:UIControlStateNormal];
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
                [self alert:error ?: @"无法加载密保问题"];
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

- (void)onSubmit:(UIButton *)sender {
    NSString *phone = [self.phoneField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (phone.length != 11) {
        [self alert:@"请输入 11 位手机号"];
        return;
    }
    NSInteger qIdx = [self.questionPicker selectedRowInComponent:0];
    if (qIdx < 0 || (NSUInteger)qIdx >= self.questions.count) {
        [self alert:@"请选择密保问题"];
        return;
    }
    NSString *sq = self.questions[(NSUInteger)qIdx];
    NSString *sa = [self.answerField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *np = self.newPassField.text ?: @"";
    NSString *c2 = self.confirmField.text ?: @"";
    if (np.length < 6 || np.length > 128) {
        [self alert:@"密码需 6-128 位"];
        return;
    }
    if (![np isEqualToString:c2]) {
        [self alert:@"两次密码不一致"];
        return;
    }
    sender.enabled = NO;
    [YLTAuthApi resetPasswordPhone:phone securityQuestion:sq securityAnswer:sa newPassword:np callback:^(BOOL ok, NSString *error) {
        sender.enabled = YES;
        if (!ok) {
            [self alert:error ?: @"重置失败"];
            return;
        }
        [self alert:@"密码已重置，请重新登录"];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)alert:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"提示" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
