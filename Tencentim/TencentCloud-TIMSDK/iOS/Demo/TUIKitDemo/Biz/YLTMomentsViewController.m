#import "YLTMomentsViewController.h"
#import "YLTMomentsApi.h"
#import "YLTMomentDetailViewController.h"
#import "YLTMomentPublishViewController.h"
#import "YLTMomentsInteractionViewController.h"
#import "YLTMomentsNotificationHelper.h"
#import "YLTDisplayNameHelper.h"
#import "YLTImageUploadClient.h"
#import "YLTMomentImageUrls.h"
#import "YLTMomentImageGridView.h"
#import "YLTMomentImageBrowseViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <ImSDK_Plus/ImSDK_Plus.h>
#import <TUICore/TUILogin.h>

static const CGFloat kCoverHeight = 180;
static const NSInteger kFeedGridTag = 5500;

@interface YLTMomentsViewController () <UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<YLTMomentItem *> *items;
@property (nonatomic, copy) NSArray<NSString *> *friendIds;
@property (nonatomic, copy) NSString *coverUrl;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, strong) UIImageView *coverView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIButton *interactionStrip;
@property (nonatomic, assign) NSInteger interactionCount;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@end

@implementation YLTMomentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"朋友圈";
    self.view.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    self.items = [NSMutableArray array];
    self.friendIds = @[];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onPublish)];

    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, kCoverHeight + 56)];
    self.coverView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.headerView.bounds.size.width, kCoverHeight)];
    self.coverView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.coverView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverView.clipsToBounds = YES;
    self.coverView.backgroundColor = [UIColor colorWithRed:0.2 green:0.45 blue:0.3 alpha:1];
    self.coverView.userInteractionEnabled = YES;
    [self.coverView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onChangeCover)]];
    [self.headerView addSubview:self.coverView];

    UILabel *coverHint = [[UILabel alloc] initWithFrame:CGRectMake(12, kCoverHeight - 28, 200, 20)];
    coverHint.text = @"点击更换封面";
    coverHint.font = [UIFont systemFontOfSize:12];
    coverHint.textColor = UIColor.whiteColor;
    [self.headerView addSubview:coverHint];

    self.interactionStrip = [UIButton buttonWithType:UIButtonTypeSystem];
    self.interactionStrip.frame = CGRectMake(0, kCoverHeight, self.headerView.bounds.size.width, 44);
    self.interactionStrip.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.interactionStrip.backgroundColor = [UIColor colorWithWhite:0.22 alpha:0.92];
    [self.interactionStrip setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.interactionStrip.titleLabel.font = [UIFont systemFontOfSize:14];
    self.interactionStrip.hidden = YES;
    [self.interactionStrip addTarget:self action:@selector(onInteractionStrip) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:self.interactionStrip];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = self.headerView;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 120;
    [self.view addSubview:self.tableView];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(onPullRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.refreshControl;

    [YLTMomentsApi fetchFriendIds:^(NSArray<NSString *> *friendIds) {
        self.friendIds = friendIds;
        [self loadCover];
        [self reloadFeed];
        [self refreshInteractionStrip];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshInteractionStrip];
}

- (void)onPullRefresh {
    [self reloadFeed];
    [self refreshInteractionStrip];
}

- (void)refreshInteractionStrip {
    long long since = [YLTMomentsNotificationHelper lastSeenMs];
    [YLTMomentsApi fetchNotificationCountsSinceMs:since callback:^(BOOL ok, YLTMomentsNotificationCounts *counts, NSString *error) {
        self.interactionCount = ok ? counts.total : 0;
        if (self.interactionCount > 0) {
            self.interactionStrip.hidden = NO;
            [self.interactionStrip setTitle:[NSString stringWithFormat:@"%ld 条新消息", (long)self.interactionCount] forState:UIControlStateNormal];
        } else {
            self.interactionStrip.hidden = YES;
        }
    }];
}

- (void)onInteractionStrip {
    YLTMomentsInteractionViewController *vc = [[YLTMomentsInteractionViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)loadCover {
    NSString *selfId = [TUILogin getUserID];
    if (selfId.length == 0) {
        return;
    }
    [YLTMomentsApi fetchCoverForUserId:selfId friendIds:self.friendIds callback:^(BOOL ok, NSString *coverUrl, NSString *error) {
        if (ok && coverUrl.length) {
            self.coverUrl = coverUrl;
            [self.coverView sd_setImageWithURL:[NSURL URLWithString:coverUrl]];
        }
    }];
}

- (void)reloadFeed {
    if (self.loading) {
        return;
    }
    self.loading = YES;
    [YLTMomentsApi fetchFeedWithFriends:self.friendIds callback:^(BOOL ok, NSArray<YLTMomentItem *> *items, NSString *error) {
        self.loading = NO;
        [self.refreshControl endRefreshing];
        if (!ok) {
            [self alert:error];
            return;
        }
        [self.items removeAllObjects];
        [self.items addObjectsFromArray:items];
        NSMutableSet *authorIds = [NSMutableSet set];
        for (YLTMomentItem *m in self.items) {
            if (m.authorUserId.length) {
                [authorIds addObject:m.authorUserId];
            }
        }
        [YLTDisplayNameHelper prefetchUserIds:authorIds.allObjects completion:^{
            [self.tableView reloadData];
        }];
    }];
}

- (void)onPublish {
    YLTMomentPublishViewController *vc = [[YLTMomentPublishViewController alloc] initWithFriendIds:self.friendIds];
    __weak typeof(self) weakSelf = self;
    vc.onPublished = ^{
        [weakSelf reloadFeed];
    };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onChangeCover {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"更换封面" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!img) {
        return;
    }
    [YLTImageUploadClient uploadImage:img callback:^(BOOL ok, NSString *imageUrl, NSString *error) {
        if (!ok) {
            [self alert:error];
            return;
        }
        [YLTMomentsApi setCoverImageUrl:imageUrl friendIds:self.friendIds callback:^(BOOL ok2, NSString *coverUrl, NSString *error2) {
            if (!ok2) {
                [self alert:error2];
                return;
            }
            self.coverUrl = coverUrl ?: imageUrl;
            [self.coverView sd_setImageWithURL:[NSURL URLWithString:self.coverUrl]];
        }];
    }];
}

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cid = @"moment";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cid];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    for (UIView *v in cell.contentView.subviews) {
        if (v.tag == kFeedGridTag) {
            [v removeFromSuperview];
        }
    }
    YLTMomentItem *m = self.items[(NSUInteger)indexPath.row];
    cell.textLabel.text = [YLTDisplayNameHelper labelForUserId:m.authorUserId];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
    NSMutableString *detail = [NSMutableString stringWithString:m.content ?: @""];
    NSString *likeText = m.liked ? @"♥ 已赞" : @"♡ 点赞";
    [detail appendFormat:@"\n%@  💬 %ld", likeText, (long)m.commentCount];
    cell.detailTextLabel.text = detail;
    cell.detailTextLabel.numberOfLines = 0;
    cell.imageView.image = nil;

    UIButton *likeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    likeBtn.frame = CGRectMake(0, 0, 44, 44);
    [likeBtn setTitle:m.liked ? @"♥" : @"♡" forState:UIControlStateNormal];
    likeBtn.titleLabel.font = [UIFont systemFontOfSize:22];
    likeBtn.tag = (NSInteger)indexPath.row;
    [likeBtn addTarget:self action:@selector(onFeedLike:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = likeBtn;

    NSArray *imgs = m.imageUrls.count ? m.imageUrls : [YLTMomentImageUrls parseToList:m.imageUrl];
    if (imgs.count) {
        YLTMomentImageGridView *grid = [[YLTMomentImageGridView alloc] init];
        grid.tag = kFeedGridTag;
        CGFloat w = tableView.bounds.size.width - 32;
        [grid bindImageUrls:imgs maxWidth:w];
        grid.frame = CGRectMake(16, 72, grid.bounds.size.width, grid.bounds.size.height);
        __weak typeof(self) weakSelf = self;
        grid.onImageTapped = ^(NSArray<NSString *> *urls, NSInteger idx) {
            [YLTMomentImageBrowseViewController presentFrom:weakSelf urls:urls startIndex:idx];
        };
        [cell.contentView addSubview:grid];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    YLTMomentItem *m = self.items[(NSUInteger)indexPath.row];
    NSArray *imgs = m.imageUrls.count ? m.imageUrls : [YLTMomentImageUrls parseToList:m.imageUrl];
    if (imgs.count == 0) {
        return UITableViewAutomaticDimension;
    }
    YLTMomentImageGridView *probe = [[YLTMomentImageGridView alloc] init];
    [probe bindImageUrls:imgs maxWidth:tableView.bounds.size.width - 32];
    return 88 + probe.bounds.size.height;
}

- (void)onFeedLike:(UIButton *)sender {
    NSInteger row = sender.tag;
    if (row < 0 || row >= (NSInteger)self.items.count) {
        return;
    }
    YLTMomentItem *m = self.items[(NSUInteger)row];
    [YLTMomentsApi toggleLikeMomentId:m.momentId friendIds:self.friendIds callback:^(BOOL ok, BOOL liked, NSInteger likeCount, NSString *error) {
        if (!ok) {
            [self alert:error];
            return;
        }
        m.liked = liked;
        m.likeCount = likeCount;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    YLTMomentItem *m = self.items[(NSUInteger)indexPath.row];
    YLTMomentDetailViewController *vc = [[YLTMomentDetailViewController alloc] initWithMomentId:m.momentId friendIds:self.friendIds];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)alert:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"提示" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
