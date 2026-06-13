#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YLTAnnouncementViewController : UIViewController

@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *htmlBody;
@property (nonatomic, copy) NSString *announcementRev;
@property (nonatomic, copy, nullable) void (^onConfirm)(void);
@property (nonatomic, copy, nullable) void (^onDefer)(void);

@end

NS_ASSUME_NONNULL_END
