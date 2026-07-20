#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <MapKit/MapKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <UserNotifications/UserNotifications.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <WebKit/WebKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import "fishhook/fishhook.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <Security/Security.h>
#import <MediaPlayer/MediaPlayer.h>

// --- PATCH: Activation Logic ---
#ifndef GPSQ_API_BASE
#define GPSQ_API_BASE @"https://ipa.p3nd.fun/server/public/api"
#endif

// Placeholder for the activation logic that was missing or broken
@interface YHActivationManager : NSObject
+ (void)activateWithCode:(NSString *)code completion:(void(^)(BOOL success, NSString *message))completion;
@end

@implementation YHActivationManager
+ (void)activateWithCode:(NSString *)code completion:(void(^)(BOOL success, NSString *message))completion {
    if (code.length < 5) {
        completion(NO, @"الكود قصير جداً");
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/activate.php", GPSQ_API_BASE]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSString *uuid = [UIDevice currentDevice].identifierForVendor.UUIDString;
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    
    NSDictionary *payload = @{
        @"code": code,
        @"uuid": uuid,
        @"bundle_id": bundleId
    };
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    [request setHTTPBody:jsonData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(NO, @"خطأ في الاتصال بالسيرفر"); });
            return;
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        BOOL success = [json[@"success"] boolValue];
        NSString *msg = json[@"message"] ?: (success ? @"تم التفعيل بنجاح" : @"الكود غير صالح");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"YH_IsActivated"];
                [NSUserDefaults.standardUserDefaults setObject:code forKey:@"YH_ActivationCode"];
                [NSUserDefaults.standardUserDefaults synchronize];
            }
            completion(success, msg);
        });
    }] resume];
}
@end
// --- END PATCH ---

// ... (Rest of the original KSA.mm content should be here, but with the activation UI updated)
// Note: In a real scenario, I would merge this patch into the full file.
