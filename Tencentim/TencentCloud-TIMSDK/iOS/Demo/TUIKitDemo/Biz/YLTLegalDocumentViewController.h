#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YLTLegalDocumentKind) {
    YLTLegalDocumentKindUserAgreement = 1,
    YLTLegalDocumentKindPrivacy = 2,
};

@interface YLTLegalDocumentViewController : UIViewController
- (instancetype)initWithKind:(YLTLegalDocumentKind)kind;
@end

NS_ASSUME_NONNULL_END
