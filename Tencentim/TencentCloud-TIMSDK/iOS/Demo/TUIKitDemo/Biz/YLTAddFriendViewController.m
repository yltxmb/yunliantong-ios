#import "YLTAddFriendViewController.h"
#import "YLTDisplayNameHelper.h"
#import "TUIC2CChatViewController.h"
#import <ImSDK_Plus/ImSDK_Plus.h>
#import <TUICore/TUILogin.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface YLTAddFriendViewController ()
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) V2TIMUserFullInfo *userInfo;
@property (nonatomic, assign) BOOL isFriend;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UIButton *actionButton;
@end

@implementation YLTAddFriendViewController

- (instancetype)initWithUserId:(NSString *)userId {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _userId = [userId copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"添加好友";
    self.view.backgroundColor = UIColor.whiteColor;

    self.avatarView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 88, 88)];
    self.avatarView.layer.cornerRadius = 8;
    self.avatarView.clipsToBounds = YES;
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
    self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.avatarView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont boldSystemFontOfSize:20];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.nameLabel];

    self.idLabel = [[UILabel alloc] init];
    self.idLabel.font = [UIFont systemFontOfSize:14];
    self.idLabel.textColor = UIColor.secondaryLabelColor;
    self.idLabel.textAlignment = NSTextAlignmentCenter;
    self.idLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.idLabel];

    self.actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [self.actionButton addTarget:self action:@selector(onAction) forControlEvents:UIControlEventTouchUpInside];
    self.actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.actionButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.avatarView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.avatarView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:48],
        [self.avatarView.widthAnchor constraintEqualToConstant:88],
        [self.avatarView.heightAnchor constraintEqualToConstant:88],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.avatarView.bottomAnchor constant:16],
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [self.idLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:8],
        [self.idLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.idLabel.trailingAnchor constraintEqualToAnchor:self.nameLabel.trailingAnchor],
        [self.actionButton.topAnchor constraintEqualToAnchor:self.idLabel.bottomAnchor constant:32],
        [self.actionButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.actionButton.widthAnchor constraintEqualToConstant:200],
        [self.actionButton.heightAnchor constraintEqualToConstant:44],
    ]];

    [self loadProfile];
}

- (void)loadProfile {
    [[V2TIMManager sharedInstance] getUsersInfo:@[self.userId] succ:^(NSArray<V2TIMUserFullInfo *> *infoList) {
        self.userInfo = infoList.firstObject;
        [self refreshUI];
        [self checkFriendship];
    } fail:^(int code, NSString *desc) {
        self.nameLabel.text = self.userId;
        self.idLabel.text = [NSString stringWithFormat:@"ID: %@", self.userId];
        [self.actionButton setTitle:@"添加好友" forState:UIControlStateNormal];
        self.actionButton.enabled = YES;
    }];
}

- (void)checkFriendship {
    [[V2TIMManager sharedInstance] checkFriend:@[self.userId] checkType:V2TIM_FRIEND_TYPE_SINGLE succ:^(NSArray<V2TIMFriendCheckResult *> *resultList) {
        V2TIMFriendCheckResult *r = resultList.firstObject;
        self.isFriend = (r.relationType == V2TIM_FRIEND_RELATION_TYPE_IN_MY_FRIEND_LIST || r.relationType == V2TIM_FRIEND_RELATION_TYPE_BOTH_WAY);
        [self refreshUI];
    } fail:^(int code, NSString *desc) {
    }];
}

- (void)refreshUI {
    NSString *nick = self.userInfo.nickName.length ? self.userInfo.nickName : self.userId;
    self.nameLabel.text = nick;
    self.idLabel.text = [NSString stringWithFormat:@"ID: %@", self.userId];
    if (self.userInfo.faceURL.length) {
        [self.avatarView sd_setImageWithURL:[NSURL URLWithString:self.userInfo.faceURL]];
    }
    if (self.isFriend) {
        [self.actionButton setTitle:@"发消息" forState:UIControlStateNormal];
    } else {
        [self.actionButton setTitle:@"添加好友" forState:UIControlStateNormal];
    }
}

- (void)onAction {
    if (self.isFriend) {
        [self openChat];
        return;
    }
    V2TIMFriendAddApplication *req = [[V2TIMFriendAddApplication alloc] init];
    req.userID = self.userId;
    req.addSource = @"AddSource_Type_QRCode";
    req.addType = V2TIM_FRIEND_TYPE_BOTH;
    [[V2TIMManager sharedInstance] addFriend:req succ:^(V2TIMFriendOperationResult *result) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已发送" message:@"好友请求已发送" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    } fail:^(int code, NSString *desc) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"失败" message:desc ?: @"添加失败" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)openChat {
    TUIChatConversationModel *conversationData = [[TUIChatConversationModel alloc] init];
    conversationData.userID = self.userId;
    conversationData.title = [YLTDisplayNameHelper labelForUserId:self.userId];
    TUIC2CChatViewController *chatVC = [[TUIC2CChatViewController alloc] init];
    chatVC.conversationData = conversationData;
    [self.navigationController pushViewController:chatVC animated:YES];
}

@end
