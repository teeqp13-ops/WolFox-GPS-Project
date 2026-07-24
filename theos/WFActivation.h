//
//  WFActivation.h
//  WolFox GPS Tweak
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFActivation : NSObject

+ (BOOL)isActivated;
+ (nullable NSString *)savedCode;

/// يرسل الكود للسيرفر ويربطه بمعرّف الجهاز، مع استدعاء completion على الـ main thread
+ (void)activateWithCode:(NSString *)code
               completion:(void (^)(BOOL success, NSString *message))completion;

/// إحداثيات المحاكاة المحفوظة محلياً
+ (CLLocationCoordinate2D)savedCoordinate;
+ (void)saveCoordinate:(CLLocationCoordinate2D)coordinate;
+ (BOOL)isSimulationEnabled;
+ (void)setSimulationEnabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
