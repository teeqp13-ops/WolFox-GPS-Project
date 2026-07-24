//
//  WFActivationViewController.m
//  WolFox Activation UI
//
//  شاشة تفعيل بمربع كود واحد + ربط كامل مع API التفعيل (HMAC-SHA256)
//

#import "WFActivationViewController.h"
#import <CommonCrypto/CommonHMAC.h>

// ====== إعدادات الاتصال - عدّل هذي القيم حسب السيرفر ======
static NSString * const kWFApiURL       = @"https://activate.p3nd.fun/api.php"; // غيّر السب دومين حسب ما تربطه فعلياً
static NSString * const kWFHMACSecret   = @"wolfox_act_9f3k2m8x_change_me";     // نفس HMAC_SECRET في config.php بالسيرفر

// ====== مفاتيح التخزين المحلي ======
static NSString * const kWFDefaultsActivatedKey = @"WF_isActivated";
static NSString * const kWFDefaultsCodeKey      = @"WF_activationCode";
static NSString * const kWFDefaultsDeviceKey    = @"WF_deviceId";

// ====== الألوان (WolFox Brand) ======
static UIColor *WFNavyColor(void)   { return [UIColor colorWithRed:0x07/255.0 green:0x0b/255.0 blue:0x18/255.0 alpha:1.0]; }
static UIColor *WFPanelColor(void)  { return [UIColor colorWithRed:0x0e/255.0 green:0x14/255.0 blue:0x2b/255.0 alpha:1.0]; }
static UIColor *WFGoldColor(void)   { return [UIColor colorWithRed:0xc9/255.0 green:0xa2/255.0 blue:0x27/255.0 alpha:1.0]; }
static UIColor *WFGold2Color(void)  { return [UIColor colorWithRed:0xe8/255.0 green:0xc4/255.0 blue:0x53/255.0 alpha:1.0]; }
static UIColor *WFMutedColor(void)  { return [UIColor colorWithRed:0x6b/255.0 green:0x74/255.0 blue:0x88/255.0 alpha:1.0]; }
static UIColor *WFSuccessColor(void){ return [UIColor colorWithRed:0x3f/255.0 green:0xd6/255.0 blue:0x8a/255.0 alpha:1.0]; }
static UIColor *WFDangerColor(void) { return [UIColor colorWithRed:0xff/255.0 green:0x5d/255.0 blue:0x6c/255.0 alpha:1.0]; }

@interface WFActivationViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIView *glowIcon;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UITextField *codeField;
@property (nonatomic, strong) UIButton *activateButton;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *deviceInfoLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation WFActivationViewController

#pragma mark - Public

+ (BOOL)isDeviceActivated {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kWFDefaultsActivatedKey];
}

+ (void)resetLocalActivation {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d removeObjectForKey:kWFDefaultsActivatedKey];
    [d removeObjectForKey:kWFDefaultsCodeKey];
    [d removeObjectForKey:kWFDefaultsDeviceKey];
    [d synchronize];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    self.view.backgroundColor = WFNavyColor();
    [self buildUI];
    [self layoutUI];
}

#pragma mark - Build UI

- (void)buildUI {
    // أيقونة داخل مربع متوهج
    self.glowIcon = [[UIView alloc] init];
    self.glowIcon.backgroundColor = [WFGoldColor() colorWithAlphaComponent:0.10];
    self.glowIcon.layer.cornerRadius = 24;
    self.glowIcon.layer.borderWidth = 1;
    self.glowIcon.layer.borderColor = [WFGoldColor() colorWithAlphaComponent:0.35].CGColor;
    self.glowIcon.layer.shadowColor = WFGoldColor().CGColor;
    self.glowIcon.layer.shadowOpacity = 0.35;
    self.glowIcon.layer.shadowRadius = 18;
    self.glowIcon.layer.shadowOffset = CGSizeZero;
    self.glowIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.glowIcon];

    UILabel *shieldLabel = [[UILabel alloc] init];
    shieldLabel.text = @"🛡";
    shieldLabel.font = [UIFont systemFontOfSize:36];
    shieldLabel.textAlignment = NSTextAlignmentCenter;
    shieldLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.glowIcon addSubview:shieldLabel];
    [NSLayoutConstraint activateConstraints:@[
        [shieldLabel.centerXAnchor constraintEqualToAnchor:self.glowIcon.centerXAnchor],
        [shieldLabel.centerYAnchor constraintEqualToAnchor:self.glowIcon.centerYAnchor],
    ]];

    // العنوان
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"تفعيل WolFox";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:21];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.titleLabel];

    // الوصف
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = @"أدخل كود التفعيل لربط هذا الجهاز وتفعيل التطبيق";
    self.subtitleLabel.textColor = WFMutedColor();
    self.subtitleLabel.font = [UIFont systemFontOfSize:12.5];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.subtitleLabel.numberOfLines = 0;
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.subtitleLabel];

    // مربع إدخال الكود (مربع واحد بدل صناديق منفصلة)
    self.codeField = [[UITextField alloc] init];
    self.codeField.placeholder = @"اكتب كود التفعيل";
    self.codeField.textColor = [UIColor whiteColor];
    self.codeField.font = [UIFont monospacedSystemFontOfSize:20 weight:UIFontWeightBold];
    self.codeField.textAlignment = NSTextAlignmentCenter;
    self.codeField.backgroundColor = WFPanelColor();
    self.codeField.layer.cornerRadius = 14;
    self.codeField.layer.borderWidth = 1;
    self.codeField.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08].CGColor;
    self.codeField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    self.codeField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.codeField.keyboardType = UIKeyboardTypeASCIICapable;
    self.codeField.delegate = self;
    self.codeField.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    self.codeField.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *padding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)];
    self.codeField.leftView = padding;
    self.codeField.leftViewMode = UITextFieldViewModeAlways;
    self.codeField.rightView = padding;
    self.codeField.rightViewMode = UITextFieldViewModeAlways;
    [self.codeField addTarget:self action:@selector(codeFieldChanged) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.codeField];

    // زر التفعيل
    self.activateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.activateButton setTitle:@"تفعيل" forState:UIControlStateNormal];
    [self.activateButton setTitleColor:WFNavyColor() forState:UIControlStateNormal];
    self.activateButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    self.activateButton.backgroundColor = WFGoldColor();
    self.activateButton.layer.cornerRadius = 14;
    self.activateButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.activateButton addTarget:self action:@selector(activateTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.activateButton];

    // مؤشر تحميل
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.color = WFNavyColor();
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    self.spinner.hidesWhenStopped = YES;
    [self.activateButton addSubview:self.spinner];

    // رسالة الحالة
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont boldSystemFontOfSize:12.5];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.alpha = 0;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    // معلومات الجهاز
    self.deviceInfoLabel = [[UILabel alloc] init];
    self.deviceInfoLabel.text = [NSString stringWithFormat:@"معرّف الجهاز: %@\nالإصدار: WolFox v1.0", [self shortDeviceId]];
    self.deviceInfoLabel.textColor = WFMutedColor();
    self.deviceInfoLabel.font = [UIFont systemFontOfSize:10.5];
    self.deviceInfoLabel.numberOfLines = 0;
    self.deviceInfoLabel.textAlignment = NSTextAlignmentCenter;
    self.deviceInfoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.deviceInfoLabel];
}

- (void)layoutUI {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.glowIcon.topAnchor constraintEqualToAnchor:safe.topAnchor constant:40],
        [self.glowIcon.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.glowIcon.widthAnchor constraintEqualToConstant:88],
        [self.glowIcon.heightAnchor constraintEqualToConstant:88],

        [self.titleLabel.topAnchor constraintEqualToAnchor:self.glowIcon.bottomAnchor constant:18],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:26],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-26],

        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:6],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:30],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-30],

        [self.codeField.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:26],
        [self.codeField.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:26],
        [self.codeField.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-26],
        [self.codeField.heightAnchor constraintEqualToConstant:54],

        [self.activateButton.topAnchor constraintEqualToAnchor:self.codeField.bottomAnchor constant:14],
        [self.activateButton.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:26],
        [self.activateButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-26],
        [self.activateButton.heightAnchor constraintEqualToConstant:48],

        [self.spinner.centerXAnchor constraintEqualToAnchor:self.activateButton.centerXAnchor],
        [self.spinner.centerYAnchor constraintEqualToAnchor:self.activateButton.centerYAnchor],

        [self.statusLabel.topAnchor constraintEqualToAnchor:self.activateButton.bottomAnchor constant:14],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:26],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-26],

        [self.deviceInfoLabel.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-18],
        [self.deviceInfoLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:26],
        [self.deviceInfoLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-26],
    ]];
}

#pragma mark - Actions

- (void)codeFieldChanged {
    self.codeField.text = [self.codeField.text uppercaseString];
}

- (void)activateTapped {
    [self.view endEditing:YES];

    NSString *code = [self.codeField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (code.length != 8) {
        [self showStatus:@"الكود يجب أن يكون 8 خانات" success:NO];
        return;
    }

    [self setLoading:YES];
    NSString *deviceId = [self persistentDeviceId];

    [self callActivationAPIWithCode:code deviceId:deviceId completion:^(BOOL success, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setLoading:NO];
            [self showStatus:message success:success];
            if (success) {
                NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
                [d setBool:YES forKey:kWFDefaultsActivatedKey];
                [d setObject:code forKey:kWFDefaultsCodeKey];
                [d setObject:deviceId forKey:kWFDefaultsDeviceKey];
                [d synchronize];
                if ([self.delegate respondsToSelector:@selector(wfActivationDidSucceedWithCode:)]) {
                    [self.delegate wfActivationDidSucceedWithCode:code];
                }
            }
        });
    }];
}

- (void)setLoading:(BOOL)loading {
    self.activateButton.enabled = !loading;
    self.activateButton.alpha = loading ? 0.6 : 1.0;
    if (loading) {
        [self.activateButton setTitle:@"" forState:UIControlStateNormal];
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
        [self.activateButton setTitle:@"تفعيل" forState:UIControlStateNormal];
    }
}

- (void)showStatus:(NSString *)text success:(BOOL)success {
    self.statusLabel.text = [NSString stringWithFormat:@"%@  %@", success ? @"✅" : @"⚠️", text];
    self.statusLabel.textColor = success ? WFSuccessColor() : WFDangerColor();
    [UIView animateWithDuration:0.25 animations:^{ self.statusLabel.alpha = 1.0; }];
}

#pragma mark - Networking (HMAC-signed activation call)

- (void)callActivationAPIWithCode:(NSString *)code
                          deviceId:(NSString *)deviceId
                        completion:(void (^)(BOOL success, NSString *message))completion {

    NSString *reqSig = [self hmacSHA256HexForString:[NSString stringWithFormat:@"%@|%@", code, deviceId]
                                                key:kWFHMACSecret];
    NSString *deviceModel = [self deviceModelString];

    NSString *bodyString = [NSString stringWithFormat:@"code=%@&device_id=%@&device_model=%@&req_sig=%@",
                             [self urlEncode:code],
                             [self urlEncode:deviceId],
                             [self urlEncode:deviceModel],
                             [self urlEncode:reqSig]];

    NSURL *url = [NSURL URLWithString:kWFApiURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    request.timeoutInterval = 15;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        if (error) {
            completion(NO, @"تعذّر الاتصال بالسيرفر، تحقق من الإنترنت");
            return;
        }

        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError || ![json isKindOfClass:[NSDictionary class]]) {
            completion(NO, @"استجابة غير صحيحة من السيرفر");
            return;
        }

        BOOL success = [json[@"success"] boolValue];
        if (success) {
            // تحقق اختياري من توقيع الرد لمنع التلاعب بالاستجابة
            NSString *timestamp = [NSString stringWithFormat:@"%@", json[@"timestamp"]];
            NSString *status = json[@"status"] ?: @"active";
            NSString *expectedSig = [self hmacSHA256HexForString:
                [NSString stringWithFormat:@"%@|%@|%@|%@", code, deviceId, timestamp, status]
                key:kWFHMACSecret];
            NSString *serverSig = json[@"signature"] ?: @"";
            if (![expectedSig isEqualToString:serverSig]) {
                completion(NO, @"فشل التحقق من صحة الاستجابة");
                return;
            }
            completion(YES, @"تم تفعيل الجهاز بنجاح");
        } else {
            NSString *errCode = json[@"error"] ?: @"unknown";
            completion(NO, [self localizedErrorForCode:errCode]);
        }
    }];
    [task resume];
}

- (NSString *)localizedErrorForCode:(NSString *)errCode {
    if ([errCode isEqualToString:@"invalid_code"]) return @"الكود غير صحيح";
    if ([errCode isEqualToString:@"used_on_other_device"]) return @"هذا الكود مستخدم على جهاز آخر";
    if ([errCode isEqualToString:@"code_revoked"]) return @"تم إيقاف هذا الكود";
    if ([errCode isEqualToString:@"code_expired"]) return @"انتهت صلاحية هذا الكود";
    if ([errCode isEqualToString:@"bad_signature"]) return @"خطأ في التحقق الأمني";
    if ([errCode isEqualToString:@"missing_params"]) return @"بيانات ناقصة";
    return @"حدث خطأ غير متوقع، حاول لاحقاً";
}

#pragma mark - Helpers

- (NSString *)persistentDeviceId {
    NSString *saved = [[NSUserDefaults standardUserDefaults] objectForKey:kWFDefaultsDeviceKey];
    if (saved.length > 0) return saved;
    NSString *vendorId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return vendorId ?: [[NSUUID UUID] UUIDString];
}

- (NSString *)deviceModelString {
    UIDevice *device = [UIDevice currentDevice];
    return [NSString stringWithFormat:@"%@ %@, iOS %@", device.model, device.name, device.systemVersion];
}

- (NSString *)shortDeviceId {
    NSString *full = [self persistentDeviceId];
    return full.length > 18 ? [full substringToIndex:18] : full;
}

- (NSString *)urlEncode:(NSString *)string {
    NSCharacterSet *allowed = [NSCharacterSet URLQueryAllowedCharacterSet];
    return [string stringByAddingPercentEncodingWithAllowedCharacters:allowed] ?: @"";
}

- (NSString *)hmacSHA256HexForString:(NSString *)string key:(NSString *)key {
    const char *cKey = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [string cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hex appendFormat:@"%02x", cHMAC[i]];
    }
    return hex;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    return newText.length <= 8;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self activateTapped];
    return YES;
}

@end
