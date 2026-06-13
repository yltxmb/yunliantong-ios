#import "YLTMyQrCodeViewController.h"
#import "YLTQrPayload.h"
#import "YLTLoginSession.h"
#import <TUICore/TUILogin.h>
#import <Photos/Photos.h>

@implementation YLTMyQrCodeViewController {
    UIImageView *_qrView;
    UILabel *_lineLabel;
    UIImage *_qrImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的二维码";
    self.view.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(onSave)];

    [[YLTLoginSession shared] loadFromDefaults];
    NSString *userId = [TUILogin getUserID] ?: [YLTLoginSession shared].userId;
    if (userId.length == 0) {
        return;
    }

    _lineLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, self.view.bounds.size.width - 40, 24)];
    _lineLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _lineLabel.textAlignment = NSTextAlignmentCenter;
    NSString *tx = [YLTLoginSession shared].txId;
    _lineLabel.text = tx.length ? [NSString stringWithFormat:@"账号：%@", tx] : userId;
    [self.view addSubview:_lineLabel];

    _qrView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 240) / 2, 150, 240, 240)];
    _qrView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _qrView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_qrView];

    NSString *payload = [YLTQrPayload buildPayloadForUserId:userId];
    _qrImage = [self qrImageFromString:payload size:520];
    _qrView.image = _qrImage;
}

- (UIImage *)qrImageFromString:(NSString *)string size:(CGFloat)size {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setValue:data forKey:@"inputMessage"];
    [filter setValue:@"M" forKey:@"inputCorrectionLevel"];
    CIImage *ci = filter.outputImage;
    if (!ci) {
        return nil;
    }
    CGFloat scale = size / ci.extent.size.width;
    CIImage *scaled = [ci imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
    return [UIImage imageWithCIImage:scaled];
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onSave {
    if (!_qrImage) {
        return;
    }
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:self->_qrImage];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *a = [UIAlertController alertControllerWithTitle:success ? @"已保存到相册" : @"保存失败" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:a animated:YES completion:nil];
        });
    }];
}

@end
