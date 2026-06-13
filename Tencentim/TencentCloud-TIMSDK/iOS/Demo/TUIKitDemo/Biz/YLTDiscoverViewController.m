#import "YLTDiscoverViewController.h"
#import "YLTMomentsViewController.h"
#import "YLTScanViewController.h"
#import "YLTMomentsNotificationHelper.h"
#import "YLTMomentsApi.h"
#import "YLTAddFriendNavigator.h"

typedef NS_ENUM(NSInteger, YLTDiscoverRow) {
    YLTDiscoverRowMoments = 0,
    YLTDiscoverRowScan,
    YLTDiscoverRowSearch,
    YLTDiscoverRowShake,
    YLTDiscoverRowNearby,
    YLTDiscoverRowShop,
    YLTDiscoverRowMiniprogram,
    YLTDiscoverRowGame,
};

@interface YLTDiscoverViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSString *> *titles;
@property (nonatomic, assign) NSInteger momentsLikeBadge;
@property (nonatomic, assign) NSInteger momentsCommentBadge;
@end

@implementation YLTDiscoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"发现";
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.titles = @[ @"朋友圈", @"扫一扫", @"搜一搜", @"摇一摇", @"附近的人", @"购物", @"小程序", @"游戏" ];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBadgeRefresh:) name:YLTMomentsBadgeRefreshNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [YLTMomentsNotificationHelper refreshDiscoverBadgeAsync];
}

- (void)onBadgeRefresh:(NSNotification *)note {
    self.momentsLikeBadge = [note.userInfo[@"likeCount"] integerValue];
    self.momentsCommentBadge = [note.userInfo[@"commentCount"] integerValue];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    }
    if (section == 1) {
        return 3;
    }
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"社交与工具";
    }
    if (section == 1) {
        return @"趣味";
    }
    return @"生活服务 / 娱乐";
}

- (NSInteger)rowIndexForIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return indexPath.row;
    }
    if (indexPath.section == 1) {
        return 2 + indexPath.row;
    }
    return 5 + indexPath.row;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cid = @"discover";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cid];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    NSInteger idx = [self rowIndexForIndexPath:indexPath];
    cell.textLabel.text = self.titles[(NSUInteger)idx];
    if (idx == YLTDiscoverRowMoments && (self.momentsLikeBadge > 0 || self.momentsCommentBadge > 0)) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"♥%ld  💬%ld", (long)self.momentsLikeBadge, (long)self.momentsCommentBadge];
        cell.detailTextLabel.textColor = [UIColor systemRedColor];
    } else {
        cell.detailTextLabel.text = nil;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger idx = [self rowIndexForIndexPath:indexPath];
    switch ((YLTDiscoverRow)idx) {
        case YLTDiscoverRowMoments: {
            YLTMomentsViewController *vc = [[YLTMomentsViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case YLTDiscoverRowScan: {
            [YLTAddFriendNavigator presentScanFromViewController:self];
            break;
        }
        default: {
            UIAlertController *a = [UIAlertController alertControllerWithTitle:@"提示" message:@"功能开发中" preferredStyle:UIAlertControllerStyleAlert];
            [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:a animated:YES completion:nil];
            break;
        }
    }
}

@end
