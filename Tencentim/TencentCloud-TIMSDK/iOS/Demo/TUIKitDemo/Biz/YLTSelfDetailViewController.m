#import "YLTSelfDetailViewController.h"
#import "YLTAvatarUploadClient.h"
#import "YLTLoginSession.h"
#import <ImSDK_Plus/ImSDK_Plus.h>
#import <TUICore/TUILogin.h>
#import <SDWebImage/UIImageView+WebCache.h>

typedef NS_ENUM(NSInteger, YLTSelfDetailRow) {
    YLTSelfDetailRowAvatar = 0,
    YLTSelfDetailRowNickname,
    YLTSelfDetailRowAccount,
    YLTSelfDetailRowPhone,
    YLTSelfDetailRowGender,
    YLTSelfDetailRowBirthday,
    YLTSelfDetailRowSignature,
};

@interface YLTSelfDetailViewController () <UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSNumber *> *rows;
@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, copy) NSString *faceUrl;
@property (nonatomic, copy) NSString *signature;
@property (nonatomic, assign) int gender;
@property (nonatomic, assign) uint32_t birthday;
@end

@implementation YLTSelfDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"个人资料";
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.rows = @[
        @(YLTSelfDetailRowAvatar),
        @(YLTSelfDetailRowNickname),
        @(YLTSelfDetailRowAccount),
        @(YLTSelfDetailRowPhone),
        @(YLTSelfDetailRowGender),
        @(YLTSelfDetailRowBirthday),
        @(YLTSelfDetailRowSignature),
    ];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
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
        self.signature = info.selfSignature ?: @"";
        self.gender = info.gender;
        self.birthday = info.birthday;
        [self.tableView reloadData];
    } fail:^(int code, NSString *desc) {
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rows.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    YLTSelfDetailRow row = (YLTSelfDetailRow)self.rows[(NSUInteger)indexPath.row].integerValue;
    return row == YLTSelfDetailRowAvatar ? 72 : 48;
}

- (NSString *)titleForRow:(YLTSelfDetailRow)row {
    switch (row) {
        case YLTSelfDetailRowAvatar: return @"头像";
        case YLTSelfDetailRowNickname: return @"昵称";
        case YLTSelfDetailRowAccount: return @"账号";
        case YLTSelfDetailRowPhone: return @"手机号";
        case YLTSelfDetailRowGender: return @"性别";
        case YLTSelfDetailRowBirthday: return @"生日";
        case YLTSelfDetailRowSignature: return @"个性签名";
    }
    return @"";
}

- (NSString *)valueForRow:(YLTSelfDetailRow)row {
    [[YLTLoginSession shared] loadFromDefaults];
    switch (row) {
        case YLTSelfDetailRowAvatar: return @"";
        case YLTSelfDetailRowNickname: return self.nickName ?: @"";
        case YLTSelfDetailRowAccount: return [YLTLoginSession shared].txId ?: @"";
        case YLTSelfDetailRowPhone: return [YLTLoginSession shared].phone ?: @"";
        case YLTSelfDetailRowGender:
            if (self.gender == 1) return @"男";
            if (self.gender == 2) return @"女";
            return @"未设置";
        case YLTSelfDetailRowBirthday: {
            if (self.birthday < 10000101) return @"未设置";
            NSString *s = [NSString stringWithFormat:@"%u", self.birthday];
            if (s.length >= 8) {
                return [NSString stringWithFormat:@"%@-%@-%@", [s substringToIndex:4], [s substringWithRange:NSMakeRange(4, 2)], [s substringFromIndex:6]];
            }
            return s;
        }
        case YLTSelfDetailRowSignature: return self.signature.length ? self.signature : @"未设置";
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YLTSelfDetailRow row = (YLTSelfDetailRow)self.rows[(NSUInteger)indexPath.row].integerValue;
    if (row == YLTSelfDetailRowAvatar) {
        static NSString *cid = @"avatar";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cid];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
            iv.tag = 101;
            iv.layer.cornerRadius = 6;
            iv.clipsToBounds = YES;
            iv.contentMode = UIViewContentModeScaleAspectFill;
            cell.accessoryView = iv;
        }
        cell.textLabel.text = @"头像";
        UIImageView *iv = (UIImageView *)cell.accessoryView;
        if (self.faceUrl.length) {
            [iv sd_setImageWithURL:[NSURL URLWithString:self.faceUrl] placeholderImage:[UIImage systemImageNamed:@"person.circle.fill"]];
        } else {
            iv.image = [UIImage systemImageNamed:@"person.circle.fill"];
        }
        return cell;
    }
    static NSString *cid = @"row";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cid];
    }
    cell.textLabel.text = [self titleForRow:row];
    cell.detailTextLabel.text = [self valueForRow:row];
    BOOL readonly = (row == YLTSelfDetailRowAccount || row == YLTSelfDetailRowPhone);
    cell.accessoryType = readonly ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = readonly ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    YLTSelfDetailRow row = (YLTSelfDetailRow)self.rows[(NSUInteger)indexPath.row].integerValue;
    switch (row) {
        case YLTSelfDetailRowAvatar:
            [self pickAvatar];
            break;
        case YLTSelfDetailRowNickname:
            [self editNickname];
            break;
        case YLTSelfDetailRowGender:
            [self editGender];
            break;
        case YLTSelfDetailRowBirthday:
            [self editBirthday];
            break;
        case YLTSelfDetailRowSignature:
            [self editSignature];
            break;
        default:
            break;
    }
}

- (void)pickAvatar {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!img) {
        return;
    }
    [YLTAvatarUploadClient uploadAvatarImage:img callback:^(BOOL ok, NSString *avatarUrl, NSString *error) {
        if (!ok) {
            [self alert:error];
            return;
        }
        V2TIMUserFullInfo *infoObj = [[V2TIMUserFullInfo alloc] init];
        infoObj.faceURL = avatarUrl;
        [[V2TIMManager sharedInstance] setSelfInfo:infoObj succ:^{
            self.faceUrl = avatarUrl;
            [self.tableView reloadData];
        } fail:^(int code, NSString *desc) {
            [self alert:desc];
        }];
    }];
}

- (void)editNickname {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改昵称" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = self.nickName;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *text = alert.textFields.firstObject.text ?: @"";
        V2TIMUserFullInfo *info = [[V2TIMUserFullInfo alloc] init];
        info.nickName = text;
        [[V2TIMManager sharedInstance] setSelfInfo:info succ:^{
            self.nickName = text;
            [self.tableView reloadData];
        } fail:^(int code, NSString *desc) {
            [self alert:desc];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)editGender {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"性别" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"男" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveGender:1];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"女" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self saveGender:2];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)saveGender:(int)g {
    V2TIMUserFullInfo *info = [[V2TIMUserFullInfo alloc] init];
    info.gender = g;
    [[V2TIMManager sharedInstance] setSelfInfo:info succ:^{
        self.gender = g;
        [self.tableView reloadData];
    } fail:^(int code, NSString *desc) {
        [self alert:desc];
    }];
}

- (void)editBirthday {
    UIDatePicker *picker = [[UIDatePicker alloc] init];
    picker.datePickerMode = UIDatePickerModeDate;
    if (@available(iOS 13.4, *)) {
        picker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"生日" message:@"\n\n\n\n\n\n\n\n\n" preferredStyle:UIAlertControllerStyleAlert];
    [alert.view addSubview:picker];
    picker.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [picker.centerXAnchor constraintEqualToAnchor:alert.view.centerXAnchor],
        [picker.topAnchor constraintEqualToAnchor:alert.view.topAnchor constant:48],
    ]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSDateComponents *c = [NSCalendar.currentCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:picker.date];
        uint32_t b = (uint32_t)(c.year * 10000 + c.month * 100 + c.day);
        V2TIMUserFullInfo *info = [[V2TIMUserFullInfo alloc] init];
        info.birthday = b;
        [[V2TIMManager sharedInstance] setSelfInfo:info succ:^{
            self.birthday = b;
            [self.tableView reloadData];
        } fail:^(int code, NSString *desc) {
            [self alert:desc];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)editSignature {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"个性签名" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = self.signature;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *text = alert.textFields.firstObject.text ?: @"";
        V2TIMUserFullInfo *info = [[V2TIMUserFullInfo alloc] init];
        info.selfSignature = text;
        [[V2TIMManager sharedInstance] setSelfInfo:info succ:^{
            self.signature = text;
            [self.tableView reloadData];
        } fail:^(int code, NSString *desc) {
            [self alert:desc];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)alert:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"提示" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
