#import "YLTLegalDocumentViewController.h"
#import "YLTPublicConfigRepository.h"
#import "YLTRuntimeApiBase.h"
#import <WebKit/WebKit.h>

@interface YLTLegalDocumentViewController () <WKNavigationDelegate>
@property (nonatomic, assign) YLTLegalDocumentKind kind;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation YLTLegalDocumentViewController

- (instancetype)initWithKind:(YLTLegalDocumentKind)kind {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _kind = kind;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.kind == YLTLegalDocumentKindPrivacy ? @"用户隐私政策" : @"用户使用协议";
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];

    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:cfg];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.center = self.view.center;
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:self.spinner];
    [self.spinner startAnimating];
    [self loadContent];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)loadContent {
    if ([YLTRuntimeApiBase appPublicConfigUrl].length == 0) {
        [self.spinner stopAnimating];
        [self.webView loadHTMLString:@"<p>未配置公开配置接口</p>" baseURL:nil];
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSDictionary *remote = [YLTPublicConfigRepository fetchRemote];
        if (remote) {
            [YLTPublicConfigRepository persist:remote];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
            [self applyConfig:remote];
        });
    });
}

- (NSString *)optString:(NSDictionary *)o keys:(NSArray<NSString *> *)keys {
    for (NSString *k in keys) {
        id v = o[k];
        if ([v isKindOfClass:NSString.class] && [(NSString *)v length]) {
            return v;
        }
    }
    return @"";
}

- (void)applyConfig:(NSDictionary *)remote {
    if (!remote) {
        [self.webView loadHTMLString:@"<p style='padding:20px'>无法从服务器加载内容，请检查网络后重试。</p>" baseURL:nil];
        return;
    }
    NSString *html = nil;
    NSString *url = nil;
    if (self.kind == YLTLegalDocumentKindPrivacy) {
        html = [self optString:remote keys:@[@"privacyPolicyHtml", @"privacy_policy_html"]];
        url = [self optString:remote keys:@[@"privacyPolicyUrl", @"privacy_policy_url"]];
    } else {
        html = [self optString:remote keys:@[@"userAgreementHtml", @"user_agreement_html"]];
        url = [self optString:remote keys:@[@"userAgreementUrl", @"user_agreement_url"]];
    }
    if (html.length) {
        NSString *page = [NSString stringWithFormat:@"<html><head><meta charset='utf-8'/><meta name='viewport' content='width=device-width,initial-scale=1'/></head><body>%@</body></html>", html];
        [self.webView loadHTMLString:page baseURL:nil];
    } else if (url.length) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    } else {
        [self.webView loadHTMLString:@"<p style='padding:20px'>后台未配置协议内容</p>" baseURL:nil];
    }
}

@end
