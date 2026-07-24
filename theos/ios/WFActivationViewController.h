//
//  WFActivationViewController.h
//  WolFox Activation UI
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WFActivationDelegate <NSObject>
@optional
- (void)wfActivationDidSucceedWithCode:(NSString *)code;
@end

@interface WFActivationViewController : UIViewController

@property (nonatomic, weak, nullable) id<WFActivationDelegate> delegate;

/// يفتح شاشة التفعيل. لو الجهاز مفعّل مسبقاً (محفوظ محلياً) يرجع YES فوراً بدون عرض الشاشة.
+ (BOOL)isDeviceActivated;

/// يمسح بيانات التفعيل المحفوظة محلياً (للاختبار / إعادة الربط)
+ (void)resetLocalActivation;

@end

NS_ASSUME_NONNULL_END
