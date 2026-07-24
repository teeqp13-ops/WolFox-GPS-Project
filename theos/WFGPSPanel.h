//
//  WFGPSPanel.h
//  WolFox GPS Tweak
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFGPSPanel : NSObject

+ (instancetype)shared;

/// يعرض زر عائم صغير فوق كل الشاشات لفتح لوحة التحكم
- (void)showFloatingButton;

/// يخفي الزر العائم (يُستدعى من زر "إخفاء زر الأداة" داخل اللوحة)
- (void)hideFloatingButton;

/// يعرض لوحة التحكم الكاملة (تفعيل + إحداثيات)
- (void)presentPanel;

@end

NS_ASSUME_NONNULL_END
