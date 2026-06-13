#import "YLTMaintenanceViewController.h"

@interface YLTMaintenanceViewController ()
@property (nonatomic, copy) NSString *message;
@end

@implementation YLTMaintenanceViewController

- (instancetype)initWithMessage:(NSString *)message {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _message = message.length ? [message copy] : @"系统维护中，请稍后再试。";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.97 blue:0.95 alpha:1];
    self.navigationItem.title = @"系统维护";
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(self.view.bounds, 32, 120)];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:17];
    label.textColor = [UIColor darkGrayColor];
    label.text = self.message;
    [self.view addSubview:label];
}

@end
