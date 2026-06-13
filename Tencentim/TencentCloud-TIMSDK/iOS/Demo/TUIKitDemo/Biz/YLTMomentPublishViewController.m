#import "YLTMomentPublishViewController.h"
#import "YLTImageUploadClient.h"
#import "YLTMomentsApi.h"
#import "YLTMomentImageUrls.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <PhotosUI/PhotosUI.h>

static const NSInteger kMaxImages = 9;
static const NSInteger kGridTag = 7700;

@interface YLTMomentPublishViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate, UIScrollViewDelegate>
@property (nonatomic, copy) NSArray<NSString *> *friendIds;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIView *gridHost;
@property (nonatomic, strong) NSMutableArray<NSString *> *uploadedUrls;
@property (nonatomic, assign) BOOL uploadInFlight;
@end

@implementation YLTMomentPublishViewController

- (instancetype)initWithFriendIds:(NSArray<NSString *> *)friendIds {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _friendIds = [friendIds copy];
        _uploadedUrls = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"发表动态";
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(onCancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发布" style:UIBarButtonItemStyleDone target:self action:@selector(onPublish)];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];

    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(16, 16, self.view.bounds.size.width - 32, 120)];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1].CGColor;
    self.textView.layer.borderWidth = 1;
    self.textView.layer.cornerRadius = 8;
    [self.scrollView addSubview:self.textView];

    self.gridHost = [[UIView alloc] initWithFrame:CGRectMake(16, 150, self.view.bounds.size.width - 32, 120)];
    self.gridHost.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.scrollView addSubview:self.gridHost];

    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(16, 280, self.view.bounds.size.width - 32, 40)];
    hint.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    hint.text = @"最多 9 张图片，点击 + 从相册选择";
    hint.font = [UIFont systemFontOfSize:13];
    hint.textColor = UIColor.grayColor;
    hint.numberOfLines = 0;
    [self.scrollView addSubview:hint];

    [self rebuildGrid];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 340);
}

- (void)onCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onPickImages {
    if (self.uploadedUrls.count >= kMaxImages) {
        [self alert:@"最多 9 张图片"];
        return;
    }
    if (@available(iOS 14, *)) {
        PHPickerConfiguration *cfg = [[PHPickerConfiguration alloc] init];
        cfg.filter = [PHPickerFilter imagesFilter];
        cfg.selectionLimit = kMaxImages - self.uploadedUrls.count;
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
    if (results.count == 0) {
        return;
    }
    for (PHPickerResult *r in results) {
        if (self.uploadedUrls.count >= kMaxImages) {
            break;
        }
        [r.itemProvider loadObjectOfClass:UIImage.class completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
            if (![object isKindOfClass:UIImage.class]) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadImage:(UIImage *)object];
            });
        }];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (img) {
        [self uploadImage:img];
    }
}

- (void)uploadImage:(UIImage *)image {
    if (self.uploadInFlight || self.uploadedUrls.count >= kMaxImages) {
        return;
    }
    self.uploadInFlight = YES;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [YLTImageUploadClient uploadImage:image callback:^(BOOL ok, NSString *imageUrl, NSString *error) {
        self.uploadInFlight = NO;
        self.navigationItem.rightBarButtonItem.enabled = YES;
        if (!ok) {
            [self alert:error ?: @"图片上传失败"];
            return;
        }
        if (imageUrl.length && self.uploadedUrls.count < kMaxImages) {
            [self.uploadedUrls addObject:imageUrl];
        }
        [self rebuildGrid];
    }];
}

- (void)rebuildGrid {
    for (UIView *v in self.gridHost.subviews) {
        [v removeFromSuperview];
    }
    NSInteger n = self.uploadedUrls.count;
    NSInteger total = n + (n < kMaxImages ? 1 : 0);
    NSInteger cols = 3;
    CGFloat gap = 4;
    CGFloat width = self.gridHost.bounds.size.width;
    CGFloat cell = floor((width - gap * (cols - 1)) / cols);
    NSInteger rows = (total + cols - 1) / cols;
    self.gridHost.frame = CGRectMake(self.gridHost.frame.origin.x, self.gridHost.frame.origin.y, width, rows * cell + MAX(0, rows - 1) * gap);
    for (NSInteger i = 0; i < total; i++) {
        NSInteger r = i / cols;
        NSInteger c = i % cols;
        CGRect frame = CGRectMake(c * (cell + gap), r * (cell + gap), cell, cell);
        if (i < n) {
            UIImageView *iv = [[UIImageView alloc] initWithFrame:frame];
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;
            iv.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
            iv.layer.cornerRadius = 6;
            [iv sd_setImageWithURL:[NSURL URLWithString:self.uploadedUrls[(NSUInteger)i]]];
            UIButton *del = [UIButton buttonWithType:UIButtonTypeSystem];
            del.frame = CGRectMake(frame.size.width - 28, 0, 28, 28);
            del.tag = kGridTag + i;
            [del setTitle:@"×" forState:UIControlStateNormal];
            del.titleLabel.font = [UIFont boldSystemFontOfSize:18];
            del.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
            [del addTarget:self action:@selector(onRemoveImage:) forControlEvents:UIControlEventTouchUpInside];
            UIView *wrap = [[UIView alloc] initWithFrame:frame];
            [wrap addSubview:iv];
            [wrap addSubview:del];
            [self.gridHost addSubview:wrap];
        } else {
            UIButton *add = [UIButton buttonWithType:UIButtonTypeSystem];
            add.frame = frame;
            add.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
            add.layer.cornerRadius = 6;
            [add setTitle:@"+" forState:UIControlStateNormal];
            add.titleLabel.font = [UIFont systemFontOfSize:28];
            [add addTarget:self action:@selector(onPickImages) forControlEvents:UIControlEventTouchUpInside];
            [self.gridHost addSubview:add];
        }
    }
}

- (void)onRemoveImage:(UIButton *)sender {
    NSInteger idx = sender.tag - kGridTag;
    if (idx >= 0 && idx < (NSInteger)self.uploadedUrls.count) {
        [self.uploadedUrls removeObjectAtIndex:(NSUInteger)idx];
        [self rebuildGrid];
    }
}

- (void)onPublish {
    if (self.uploadInFlight) {
        [self alert:@"图片上传中，请稍候"];
        return;
    }
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0 && self.uploadedUrls.count == 0) {
        [self alert:@"请输入文字或选择图片"];
        return;
    }
    self.navigationItem.rightBarButtonItem.enabled = NO;
    NSString *field = [YLTMomentImageUrls toStorageField:self.uploadedUrls];
    [YLTMomentsApi publishContent:text imageStorageField:field friendIds:self.friendIds callback:^(BOOL ok, NSString *error) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        if (!ok) {
            [self alert:error ?: @"发布失败"];
            return;
        }
        if (self.onPublished) {
            self.onPublished();
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)alert:(NSString *)msg {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"提示" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end
