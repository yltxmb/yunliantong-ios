#import "YLTMomentDetailViewController.h"
#import "YLTMomentsApi.h"
#import "YLTDisplayNameHelper.h"
#import "YLTMomentImageUrls.h"
#import "YLTMomentImageGridView.h"
#import "YLTMomentImageBrowseViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

static const NSInteger kPostGridTag = 6100;

@interface YLTMomentDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, assign) int64_t momentId;
@property (nonatomic, copy) NSArray<NSString *> *friendIds;
@property (nonatomic, strong) YLTMomentThread *thread;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIView *inputBar;
@property (nonatomic, strong) UIButton *replyCancelBtn;
@property (nonatomic, assign) int64_t replyToCommentId;
@property (nonatomic, copy) NSString *replyToAuthorId;
@end

@implementation YLTMomentDetailViewController

- (instancetype)initWithMomentId:(int64_t)momentId friendIds:(NSArray<NSString *> *)friendIds {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _momentId = momentId;
        _friendIds = [friendIds copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"动态详情";
    self.view.backgroundColor = UIColor.whiteColor;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 80;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.view addSubview:self.tableView];

    self.inputBar = [[UIView alloc] init];
    self.inputBar.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    self.inputField = [[UITextField alloc] init];
    self.inputField.placeholder = @"写评论…";
    self.inputField.borderStyle = UITextBorderStyleRoundedRect;
    self.inputField.delegate = self;
    UIButton *send = [UIButton buttonWithType:UIButtonTypeSystem];
    [send setTitle:@"发送" forState:UIControlStateNormal];
    [send addTarget:self action:@selector(onSend) forControlEvents:UIControlEventTouchUpInside];
    self.replyCancelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.replyCancelBtn setTitle:@"取消回复" forState:UIControlStateNormal];
    self.replyCancelBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    self.replyCancelBtn.hidden = YES;
    [self.replyCancelBtn addTarget:self action:@selector(cancelReply) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBar addSubview:self.replyCancelBtn];
    [self.inputBar addSubview:self.inputField];
    [self.inputBar addSubview:send];
    send.tag = 100;
    [self.view addSubview:self.inputBar];

    [self loadThread];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat barH = 72 + self.view.safeAreaInsets.bottom;
    self.inputBar.frame = CGRectMake(0, self.view.bounds.size.height - barH, self.view.bounds.size.width, barH);
    self.replyCancelBtn.frame = CGRectMake(12, 4, 80, 20);
    self.inputField.frame = CGRectMake(12, 28, self.view.bounds.size.width - 80, 36);
    UIButton *send = [self.inputBar viewWithTag:100];
    send.frame = CGRectMake(self.view.bounds.size.width - 64, 28, 52, 36);
    self.tableView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - barH);
}

- (void)loadThread {
    [YLTMomentsApi fetchThreadMomentId:self.momentId friendIds:self.friendIds callback:^(BOOL ok, YLTMomentThread *thread, NSString *error) {
        if (!ok) {
            [self alert:error];
            return;
        }
        self.thread = thread;
        NSMutableSet *ids = [NSMutableSet set];
        if (thread.post.authorUserId.length) {
            [ids addObject:thread.post.authorUserId];
        }
        for (YLTMomentComment *c in thread.comments) {
            if (c.authorUserId.length) {
                [ids addObject:c.authorUserId];
            }
            if (c.parentCommentId > 0) {
                for (YLTMomentComment *p in thread.comments) {
                    if (p.commentId == c.parentCommentId && p.authorUserId.length) {
                        [ids addObject:p.authorUserId];
                        break;
                    }
                }
            }
        }
        [YLTDisplayNameHelper prefetchUserIds:ids.allObjects completion:^{
            [self.tableView reloadData];
        }];
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.thread ? 2 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : self.thread.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *cid = @"post";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cid];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        for (UIView *v in cell.contentView.subviews) {
            if (v.tag == kPostGridTag) {
                [v removeFromSuperview];
            }
        }
        YLTMomentItem *p = self.thread.post;
        cell.textLabel.text = [YLTDisplayNameHelper labelForUserId:p.authorUserId];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n♥ %ld  💬 %ld", p.content ?: @"", (long)p.likeCount, (long)p.commentCount];
        cell.detailTextLabel.numberOfLines = 0;
        NSArray *imgs = p.imageUrls.count ? p.imageUrls : [YLTMomentImageUrls parseToList:p.imageUrl];
        if (imgs.count) {
            YLTMomentImageGridView *grid = [[YLTMomentImageGridView alloc] init];
            grid.tag = kPostGridTag;
            CGFloat w = tableView.bounds.size.width - 32;
            [grid bindImageUrls:imgs maxWidth:w];
            grid.frame = CGRectMake(16, 90, grid.bounds.size.width, grid.bounds.size.height);
            __weak typeof(self) weakSelf = self;
            grid.onImageTapped = ^(NSArray<NSString *> *urls, NSInteger idx) {
                [YLTMomentImageBrowseViewController presentFrom:weakSelf urls:urls startIndex:idx];
            };
            [cell.contentView addSubview:grid];
        }
        return cell;
    }
    static NSString *cid = @"cmt";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cid];
        UIButton *reply = [UIButton buttonWithType:UIButtonTypeSystem];
        reply.tag = 900;
        reply.titleLabel.font = [UIFont systemFontOfSize:13];
        [reply setTitle:@"回复" forState:UIControlStateNormal];
        cell.accessoryView = reply;
    }
    YLTMomentComment *c = self.thread.comments[(NSUInteger)indexPath.row];
    NSString *name = [YLTDisplayNameHelper labelForUserId:c.authorUserId];
    NSString *display = nil;
    if (c.parentCommentId > 0) {
        NSString *parentName = [self parentAuthorLabel:c.parentCommentId];
        if (parentName.length) {
            display = [NSString stringWithFormat:@"%@ 回复 %@：%@", name, parentName, c.content];
        }
    }
    if (!display) {
        display = [NSString stringWithFormat:@"%@：%@", name, c.content];
    }
    cell.textLabel.text = display;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.detailTextLabel.text = c.createdAt;
    UIButton *reply = (UIButton *)cell.accessoryView;
    reply.tag = (NSInteger)indexPath.row;
    [reply removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [reply addTarget:self action:@selector(onReplyComment:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

- (NSString *)parentAuthorLabel:(int64_t)parentCommentId {
    for (YLTMomentComment *x in self.thread.comments) {
        if (x.commentId == parentCommentId) {
            return [YLTDisplayNameHelper labelForUserId:x.authorUserId];
        }
    }
    return @"";
}

- (void)onReplyComment:(UIButton *)sender {
    NSInteger row = sender.tag;
    if (row < 0 || row >= (NSInteger)self.thread.comments.count) {
        return;
    }
    YLTMomentComment *c = self.thread.comments[(NSUInteger)row];
    self.replyToCommentId = c.commentId;
    self.replyToAuthorId = c.authorUserId;
    NSString *name = [YLTDisplayNameHelper labelForUserId:c.authorUserId];
    self.inputField.placeholder = [NSString stringWithFormat:@"回复 %@…", name];
    self.replyCancelBtn.hidden = NO;
    [self.inputField becomeFirstResponder];
}

- (void)cancelReply {
    self.replyToCommentId = 0;
    self.replyToAuthorId = nil;
    self.inputField.placeholder = @"写评论…";
    self.replyCancelBtn.hidden = YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && self.thread.post) {
        NSArray *imgs = self.thread.post.imageUrls.count ? self.thread.post.imageUrls : [YLTMomentImageUrls parseToList:self.thread.post.imageUrl];
        if (imgs.count == 0) {
            return UITableViewAutomaticDimension;
        }
        CGFloat w = tableView.bounds.size.width - 32;
        YLTMomentImageGridView *probe = [[YLTMomentImageGridView alloc] init];
        [probe bindImageUrls:imgs maxWidth:w];
        return 100 + probe.bounds.size.height;
    }
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        [YLTMomentsApi toggleLikeMomentId:self.momentId friendIds:self.friendIds callback:^(BOOL ok, BOOL liked, NSInteger likeCount, NSString *error) {
            if (ok) {
                self.thread.post.liked = liked;
                self.thread.post.likeCount = likeCount;
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
            }
        }];
    }
}

- (void)onSend {
    NSString *text = [self.inputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (text.length == 0) {
        return;
    }
    int64_t parentId = self.replyToCommentId;
    [YLTMomentsApi postCommentMomentId:self.momentId content:text parentCommentId:parentId friendIds:self.friendIds callback:^(BOOL ok, NSString *error) {
        if (!ok) {
            [self alert:error];
            return;
        }
        self.inputField.text = @"";
        [self cancelReply];
        [self loadThread];
    }];
}

- (void)alert:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"提示" message:msg ?: @"" preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
