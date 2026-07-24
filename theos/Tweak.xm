//
//  Tweak.xm
//  WolFox GPS Tweak
//
//  محاكاة الموقع على مستوى النظام لكل التطبيقات، مع بوابة تفعيل مرتبطة بسيرفر WolFox
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "WFActivation.h"
#import "WFGPSPanel.h"

static CLLocation *WFFakeLocation(void) {
    CLLocationCoordinate2D coord = [WFActivation savedCoordinate];
    return [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
}

static BOOL WFShouldSimulate(void) {
    return [WFActivation isActivated] && [WFActivation isSimulationEnabled];
}

#pragma mark - Hook: CLLocationManager

%hook CLLocationManager

- (CLLocation *)location {
    if (WFShouldSimulate()) {
        return WFFakeLocation();
    }
    return %orig;
}

- (void)startUpdatingLocation {
    %orig;
    if (WFShouldSimulate()) {
        CLLocation *fake = WFFakeLocation();
        id<CLLocationManagerDelegate> delegate = self.delegate;
        if ([delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate locationManager:self didUpdateLocations:@[fake]];
            });
        }
    }
}

%end

#pragma mark - Hook: SpringBoard (لعرض الزر العائم عند تشغيل الجهاز)

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[WFGPSPanel shared] showFloatingButton];
    });
}

%end

%ctor {
    @autoreleasepool {
        // لا شي إضافي وقت التحميل - التفعيل والمحاكاة تتحكم فيهم WFActivation
    }
}
