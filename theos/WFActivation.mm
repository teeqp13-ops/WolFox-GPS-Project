//
//  WFActivation.mm
//  WolFox GPS Tweak
//

#import "WFActivation.h"
#import "WFConfig.h"
#import <UIKit/UIKit.h>

static NSString *WFDeviceId(void) {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:WF_PREFS_PATH] ?: [NSMutableDictionary dictionary];
    NSString *existing = prefs[@"device_id"];
    if (existing.length > 0) return existing;

    NSString *newId = [[NSUUID UUID] UUIDString];
    prefs[@"device_id"] = newId;
    [prefs writeToFile:WF_PREFS_PATH atomically:YES];
    return newId;
}

@implementation WFActivation

+ (NSMutableDictionary *)loadPrefs {
    return [NSMutableDictionary dictionaryWithContentsOfFile:WF_PREFS_PATH] ?: [NSMutableDictionary dictionary];
}

+ (void)savePrefs:(NSDictionary *)prefs {
    [prefs writeToFile:WF_PREFS_PATH atomically:YES];
}

+ (BOOL)isActivated {
    NSDictionary *prefs = [self loadPrefs];
    return [prefs[@"is_activated"] boolValue];
}

+ (nullable NSString *)savedCode {
    return [self loadPrefs][@"code"];
}

+ (CLLocationCoordinate2D)savedCoordinate {
    NSDictionary *prefs = [self loadPrefs];
    double lat = [prefs[@"lat"] doubleValue];
    double lng = [prefs[@"lng"] doubleValue];
    return CLLocationCoordinate2DMake(lat, lng);
}

+ (void)saveCoordinate:(CLLocationCoordinate2D)coordinate {
    NSMutableDictionary *prefs = [self loadPrefs];
    prefs[@"lat"] = @(coordinate.latitude);
    prefs[@"lng"] = @(coordinate.longitude);
    [self savePrefs:prefs];
}

+ (BOOL)isSimulationEnabled {
    NSDictionary *prefs = [self loadPrefs];
    return [prefs[@"sim_enabled"] boolValue];
}

+ (void)setSimulationEnabled:(BOOL)enabled {
    NSMutableDictionary *prefs = [self loadPrefs];
    prefs[@"sim_enabled"] = @(enabled);
    [self savePrefs:prefs];
}

+ (void)activateWithCode:(NSString *)code completion:(void (^)(BOOL, NSString *))completion {
    NSString *deviceId = WFDeviceId();
    NSString *deviceLabel = [UIDevice currentDevice].name ?: @"iPhone";
    NSString *body = [NSString stringWithFormat:@"project_key=%@&code=%@&device_id=%@&device_label=%@&bundle_id=%@",
                       [self urlEncode:WF_PROJECT_KEY],
                       [self urlEncode:code],
                       [self urlEncode:deviceId],
                       [self urlEncode:deviceLabel],
                       [self urlEncode:WF_BUNDLE_ID]];

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:WF_API_URL]];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    req.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    req.timeoutInterval = 15;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) { completion(NO, @"تعذّر الاتصال بالسيرفر"); return; }
            NSError *jsonErr = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];
            if (jsonErr || ![json isKindOfClass:[NSDictionary class]]) {
                completion(NO, @"استجابة غير صحيحة من السيرفر"); return;
            }
            if ([json[@"success"] boolValue]) {
                NSMutableDictionary *prefs = [self loadPrefs];
                prefs[@"is_activated"] = @(YES);
                prefs[@"code"] = code;
                [self savePrefs:prefs];
                completion(YES, @"تم تفعيل الجهاز بنجاح");
            } else {
                NSString *err = json[@"error"] ?: @"unknown";
                completion(NO, [self localizedError:err]);
            }
        });
    }];
    [task resume];
}

+ (NSString *)localizedError:(NSString *)code {
    if ([code isEqualToString:@"invalid_code"]) return @"الكود غير صحيح";
    if ([code isEqualToString:@"invalid_project"]) return @"مشروع WolFox GPS غير مضاف أو غير مفعّل في اللوحة";
    if ([code isEqualToString:@"device_limit_reached"]) return @"تم الوصول إلى حد الأجهزة المسموح";
    if ([code isEqualToString:@"disabled"] || [code isEqualToString:@"suspended"]) return @"تم إيقاف هذا الكود";
    if ([code isEqualToString:@"expired"]) return @"انتهت صلاحية الكود";
    if ([code isEqualToString:@"maintenance"]) return @"الخدمة تحت الصيانة";
    if ([code isEqualToString:@"missing_fields"]) return @"بيانات التفعيل ناقصة";
    return @"حدث خطأ غير متوقع";
}

+ (NSString *)urlEncode:(NSString *)s {
    return [s stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] ?: @"";
}

@end
