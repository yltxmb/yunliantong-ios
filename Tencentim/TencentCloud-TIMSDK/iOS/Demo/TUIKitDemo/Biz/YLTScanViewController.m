#import "YLTScanViewController.h"
#import "YLTQrPayload.h"
#import "YLTAddFriendNavigator.h"
#import "YLTLoginSession.h"
#import <TUICore/TUICore.h>
#import <TUICore/TUILogin.h>
#import <TUICore/TUITool.h>
#import <PhotosUI/PhotosUI.h>
#import <Vision/Vision.h>
#import <CoreImage/CoreImage.h>

@interface YLTScanViewController () <AVCaptureMetadataOutputObjectsDelegate, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign) BOOL handled;
@end

@implementation YLTScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"扫一扫";
    self.view.backgroundColor = UIColor.blackColor;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(onClose)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(onPickAlbum)];
    [self setupCamera];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.previewLayer.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.session && !self.session.isRunning) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [self.session startRunning];
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
}

- (void)setupCamera {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectInset(self.view.bounds, 24, 100)];
        lab.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        lab.textColor = UIColor.whiteColor;
        lab.numberOfLines = 0;
        lab.textAlignment = NSTextAlignmentCenter;
        lab.text = @"请在系统设置中允许访问相机以使用扫一扫";
        [self.view addSubview:lab];
        return;
    }
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) {
        return;
    }
    NSError *err = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&err];
    if (!input) {
        return;
    }
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    self.session = [[AVCaptureSession alloc] init];
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    if ([self.session canAddOutput:output]) {
        [self.session addOutput:output];
    }
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (self.handled) {
        return;
    }
    for (AVMetadataObject *obj in metadataObjects) {
        if (![obj isKindOfClass:AVMetadataMachineReadableCodeObject.class]) {
            continue;
        }
        NSString *value = [(AVMetadataMachineReadableCodeObject *)obj stringValue];
        if (value.length == 0) {
            continue;
        }
        self.handled = YES;
        [self.session stopRunning];
        [self handleScanResult:value fromAlbum:NO];
        break;
    }
}

- (void)onPickAlbum {
    if (@available(iOS 14, *)) {
        PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
        cfg.filter = [PHPickerFilter imagesFilter];
        cfg.selectionLimit = 1;
        PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:cfg];
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14)) {
    [picker dismissViewControllerAnimated:YES completion:nil];
    PHPickerResult *r = results.firstObject;
    if (!r) {
        return;
    }
    [r.itemProvider loadObjectOfClass:UIImage.class completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
        if (![object isKindOfClass:UIImage.class]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self toast:@"无法识别二维码"];
            });
            return;
        }
        [self decodeQrFromImage:(UIImage *)object];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (img) {
        [self decodeQrFromImage:img];
    }
}

- (void)decodeQrFromImage:(UIImage *)image {
    if (@available(iOS 11.0, *)) {
        CGImageRef cg = image.CGImage;
        if (!cg) {
            [self toast:@"无法识别二维码"];
            return;
        }
        VNDetectBarcodesRequest *req = [[VNDetectBarcodesRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                for (VNBarcodeObservation *obs in request.results) {
                    if (obs.payloadStringValue.length) {
                        [self handleScanResult:obs.payloadStringValue fromAlbum:YES];
                        return;
                    }
                }
                [self toast:@"无法识别二维码"];
            });
        }];
        req.symbologies = @[ VNBarcodeSymbologyQR ];
        VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:cg options:@{}];
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSError *err = nil;
            [handler performRequests:@[ req ] error:&err];
        });
        return;
    }
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    CIImage *ci = [[CIImage alloc] initWithImage:image];
    NSArray *features = [detector featuresInImage:ci];
    for (CIQRCodeFeature *f in features) {
        if (f.messageString.length) {
            [self handleScanResult:f.messageString fromAlbum:YES];
            return;
        }
    }
    [self toast:@"无法识别二维码"];
}

- (void)handleScanResult:(NSString *)value fromAlbum:(BOOL)fromAlbum {
    NSString *userId = [YLTQrPayload parseUserIdFromQrText:value];
    if (userId.length) {
        NSString *selfId = [TUILogin getUserID];
        if (selfId.length && [selfId isEqualToString:userId]) {
            if (fromAlbum) {
                [self toast:@"不能扫描自己的二维码"];
            } else {
                [self alertMessage:@"不能扫描自己的二维码" restartScan:YES];
            }
            return;
        }
        __weak typeof(self) weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            UIViewController *host = weakSelf.presentingViewController ?: weakSelf;
            while (host.presentedViewController) {
                host = host.presentedViewController;
            }
            [YLTAddFriendNavigator openAddFriendFromViewController:host userId:userId];
        }];
        return;
    }
    if (fromAlbum) {
        [self toast:@"未识别到有效的好友二维码"];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"扫描结果" message:value preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([value hasPrefix:@"http://"] || [value hasPrefix:@"https://"]) {
            [TUITool openLinkWithURL:[NSURL URLWithString:value]];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)toast:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:a animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [a dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

- (void)onClose {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)alertMessage:(NSString *)msg restartScan:(BOOL)restart {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (restart) {
            self.handled = NO;
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                [self.session startRunning];
            });
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
