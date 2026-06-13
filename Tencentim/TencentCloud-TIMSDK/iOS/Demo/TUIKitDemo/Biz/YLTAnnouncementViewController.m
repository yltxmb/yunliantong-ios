#import "YLTAnnouncementViewController.h"
#import <WebKit/WebKit.h>

@implementation YLTAnnouncementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
    CGFloat w = self.view.bounds.size.width * 0.92;
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - w) / 2, 120, w, self.view.bounds.size.height - 240)];
    card.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 12;
    card.clipsToBounds = YES;
    [self.view addSubview:card];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, w - 32, 28)];
    title.font = [UIFont boldSystemFontOfSize:18];
    title.text = self.titleText.length ? self.titleText : @"公告";
    [card addSubview:title];

    WKWebView *web = [[WKWebView alloc] initWithFrame:CGRectMake(0, 52, w, card.bounds.size.height - 120)];
    web.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    web.backgroundColor = UIColor.clearColor;
    web.opaque = NO;
    [card addSubview:web];

    NSString *body = self.htmlBody.length ? self.htmlBody : [NSString stringWithFormat:@"<p style=\"color:#64748B;\">%@</p>", self.titleText ?: @""];
    NSString *page = [NSString stringWithFormat:@"<!DOCTYPE html><html><head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><style>body{font-family:-apple-system,sans-serif;font-size:15px;line-height:1.5;margin:12px;color:#334155;}img{max-width:100%%;}</style></head><body>%@</body></html>", body];
    [web loadHTMLString:page baseURL:nil];

    UIButton *later = [UIButton buttonWithType:UIButtonTypeSystem];
    later.frame = CGRectMake(16, card.bounds.size.height - 52, (w - 40) / 2, 40);
    later.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
    [later setTitle:@"稍后" forState:UIControlStateNormal];
    [later addTarget:self action:@selector(onLater) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:later];

    UIButton *ok = [UIButton buttonWithType:UIButtonTypeSystem];
    ok.frame = CGRectMake(w / 2 + 4, card.bounds.size.height - 52, (w - 40) / 2, 40);
    ok.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [ok setTitle:@"知道了" forState:UIControlStateNormal];
    ok.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [ok addTarget:self action:@selector(onOk) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:ok];
}

- (void)onOk {
    if (self.onConfirm) {
        self.onConfirm();
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onLater {
    if (self.onDefer) {
        self.onDefer();
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
