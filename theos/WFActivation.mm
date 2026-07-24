//
//  WFActivation.mm
//  WolFox GPS Tweak
//

#import "WFActivation.h"
#import "WFConfig.h"
#import <CommonCrypto/CommonHMAC.h>
#import <UIKit/UIKit.h>

static NSString *WFHMACHex(NSString *string, NSString *key) {
    const char *cKey = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [string cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) { [hex appendFormat:@"%02x", cHMAC[i]]; }
    return hex;
}

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
    NSString *reqSig = WFHMACHex([NSString stringWithFormat:@"%@|%@", code, deviceId], WF_HMAC_SECRET);

    NSString *body = [NSString stringWithFormat:@"code=%@&device_id=%@&req_sig=%@",
                       [self urlEncode:code], [self urlEncode:deviceId], [self urlEncode:reqSig]];

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
    if ([code isEqualToString:@"used_on_other_device"]) return @"مستخدم على جهاز آخر";
    if ([code isEqualToString:@"code_revoked"]) return @"تم إيقاف هذا الكود";
    if ([code isEqualToString:@"code_expired"]) return @"انتهت صلاحية الكود";
    return @"حدث خطأ غير متوقع";
}

+ (NSString *)urlEncode:(NSString *)s {
    return [s stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] ?: @"";
}

@end
