#import "YLTMomentsInteractionViewController.h"
#import "YLTMomentsApi.h"
#import "YLTMomentsNotificationHelper.h"
#import "YLTDisplayNameHelper.h"
#import "YLTMomentDetailViewController.h"

@interface YLTMomentsInteractionViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<YLTMomentInteractionItem *> *items;
@property (nonatomic, copy) NSArray<NSString *> *friendIds;
@end

@implementation YLTMomentsInteractionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"消息";
    self.view.backgroundColor = UIColor.whiteColor;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 64;
    [self.view addSubview:self.tableView];

    [YLTMomentsApi fetchFriendIds:^(NSArray<NSString *> *friendIds) {
        self.friendIds = friendIds;
        [self loadItems];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        [YLTMomentsNotificationHelper markSeenAndRefreshBadges];
    }
}

- (void)loadItems {
    long long since = [YLTMomentsNotificationHelper lastSeenMs];
    [YLTMomentsApi fetchNotificationsSinceMs:since callback:^(BOOL ok, NSArray<YLTMomentInteractionItem *> *items, NSString *error) {
        if (!ok) {
            return;
        }
        NSMutableSet *ids = [NSMutableSet set];
        for (YLTMomentInteractionItem *it in items) {
            if (it.actorUserId.length) {
                [ids addObject:it.actorUserId];
            }
        }
        [YLTDisplayNameHelper prefetchUserIds:ids.allObjects completion:^{
            self.items = items;
            [self.tableView reloadData];
        }];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cid = @"interaction";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cid];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    YLTMomentInteractionItem *it = self.items[(NSUInteger)indexPath.row];
    NSString *name = [YLTDisplayNameHelper labelForUserId:it.actorUserId];
    if ([it.type isEqualToString:@"like"]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ 赞了你的动态", name];
        cell.detailTextLabel.text = it.createdAt;
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ 评论了你", name];
        cell.detailTextLabel.text = it.content.length ? it.content : it.createdAt;
    }
    cell.detailTextLabel.numberOfLines = 2;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    YLTMomentInteractionItem *it = self.items[(NSUInteger)indexPath.row];
    if (it.momentId <= 0) {
        return;
    }
    YLTMomentDetailViewController *vc = [[YLTMomentDetailViewController alloc] initWithMomentId:it.momentId friendIds:self.friendIds];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
