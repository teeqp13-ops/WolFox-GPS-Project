//
//  WFGPSPanel.mm
//  Fake GPS Tweak (WolFox)
//
//  شاشة كاملة: بوابة تفعيل إجبارية أولاً، ثم شاشة المميزات (خريطة + أزرار)
//

#import "WFGPSPanel.h"
#import "WFActivation.h"
#import <MapKit/MapKit.h>

static UIColor *WFNavy(void)   { return [UIColor colorWithRed:0x07/255.0 green:0x0b/255.0 blue:0x18/255.0 alpha:1.0]; }
static UIColor *WFPanelC(void) { return [UIColor colorWithRed:0x0e/255.0 green:0x14/255.0 blue:0x2b/255.0 alpha:1.0]; }
static UIColor *WFGold(void)   { return [UIColor colorWithRed:0xc9/255.0 green:0xa2/255.0 blue:0x27/255.0 alpha:1.0]; }
static UIColor *WFGold2(void)  { return [UIColor colorWithRed:0xe8/255.0 green:0xc4/255.0 blue:0x53/255.0 alpha:1.0]; }
static UIColor *WFMuted(void)  { return [UIColor colorWithRed:0x6b/255.0 green:0x74/255.0 blue:0x88/255.0 alpha:1.0]; }
static UIColor *WFSuccess(void){ return [UIColor colorWithRed:0x3f/255.0 green:0xd6/255.0 blue:0x8a/255.0 alpha:1.0]; }
static UIColor *WFDanger(void) { return [UIColor colorWithRed:0xff/255.0 green:0x5d/255.0 blue:0x6c/255.0 alpha:1.0]; }

@interface WFGPSPanel () <UITextFieldDelegate, MKMapViewDelegate>

@property (nonatomic, strong) UIWindow *floatingWindow;
@property (nonatomic, strong) UIWindow *panelWindow;

// حالة 1: التفعيل
@property (nonatomic, strong) UIView *activationView;
@property (nonatomic, strong) UITextField *codeField;
@property (nonatomic, strong) UILabel *actStatusLabel;
@property (nonatomic, strong) UIButton *activateButton;

// حالة 2: المميزات
@property (nonatomic, strong) UIView *featuresView;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) MKPointAnnotation *pin;
@property (nonatomic, strong) UISwitch *moveLocationSwitch;
@property (nonatomic, strong) UISwitch *simulateMovementSwitch;

@end

@implementation WFGPSPanel

+ (instancetype)shared {
    static WFGPSPanel *inst = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ inst = [WFGPSPanel new]; });
    return inst;
}

#pragma mark - الزر العائم

- (void)showFloatingButton {
    if (self.floatingWindow) { self.floatingWindow.hidden = NO; return; }

    UIWindow *win = [[UIWindow alloc] initWithFrame:CGRectMake(20, 100, 54, 54)];
    win.windowLevel = UIWindowLevelStatusBar + 100;
    win.backgroundColor = [UIColor clearColor];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = win.bounds;
    btn.backgroundColor = WFGold();
    btn.layer.cornerRadius = 27;
    btn.layer.shadowColor = [UIColor blackColor].CGColor;
    btn.layer.shadowOpacity = 0.4;
    btn.layer.shadowRadius = 8;
    [btn setTitle:@"📍" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:22];
    [btn addTarget:self action:@selector(presentPanel) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
    [btn addGestureRecognizer:pan];

    [win addSubview:btn];
    win.rootViewController = [UIViewController new];
    win.hidden = NO;
    self.floatingWindow = win;
}

- (void)hideFloatingButton {
    self.floatingWindow.hidden = YES;
}

- (void)handleDrag:(UIPanGestureRecognizer *)gesture {
    UIWindow *win = self.floatingWindow;
    CGPoint translation = [gesture translationInView:win];
    win.center = CGPointMake(win.center.x + translation.x, win.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:win];
}

#pragma mark - اللوحة الكاملة (شاشة كاملة بدل بطاقة صغيرة)

- (void)presentPanel {
    if (self.panelWindow) {
        self.panelWindow.hidden = NO;
        [self refreshStateForActivation];
        return;
    }

    UIWindow *win = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    win.windowLevel = UIWindowLevelAlert + 100;
    win.backgroundColor = WFNavy();

    UIViewController *rootVC = [UIViewController new];
    rootVC.view.backgroundColor = WFNavy();
    win.rootViewController = rootVC;

    UIView *root = rootVC.view;

    // ===== الشريط العلوي: زر رجوع + شارة العلامة =====
    UIView *topbar = [[UIView alloc] init];
    topbar.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:topbar];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [backBtn setTitle:@"➜" forState:UIControlStateNormal];
    backBtn.transform = CGAffineTransformMakeRotation(M_PI); // سهم يشير لليمين (RTL)
    [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    backBtn.backgroundColor = WFPanelC();
    backBtn.layer.cornerRadius = 9;
    backBtn.layer.borderWidth = 1;
    backBtn.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08].CGColor;
    backBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [backBtn addTarget:self action:@selector(dismissPanel) forControlEvents:UIControlEventTouchUpInside];
    [topbar addSubview:backBtn];

    UIView *badge = [[UIView alloc] init];
    badge.backgroundColor = WFPanelC();
    badge.layer.cornerRadius = 8;
    badge.layer.borderWidth = 1;
    badge.layer.borderColor = [WFGold() colorWithAlphaComponent:0.25].CGColor;
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    [topbar addSubview:badge];

    UILabel *badgeLabel = [[UILabel alloc] init];
    badgeLabel.text = @"📍 Fake GPS";
    badgeLabel.textColor = WFGold2();
    badgeLabel.font = [UIFont boldSystemFontOfSize:11];
    badgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [badge addSubview:badgeLabel];

    [NSLayoutConstraint activateConstraints:@[
        [topbar.topAnchor constraintEqualToAnchor:root.safeAreaLayoutGuide.topAnchor constant:12],
        [topbar.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:16],
        [topbar.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-16],
        [topbar.heightAnchor constraintEqualToConstant:34],

        [backBtn.leadingAnchor constraintEqualToAnchor:topbar.leadingAnchor],
        [backBtn.centerYAnchor constraintEqualToAnchor:topbar.centerYAnchor],
        [backBtn.widthAnchor constraintEqualToConstant:32],
        [backBtn.heightAnchor constraintEqualToConstant:32],

        [badge.centerYAnchor constraintEqualToAnchor:topbar.centerYAnchor],
        [badge.trailingAnchor constraintEqualToAnchor:topbar.trailingAnchor],
        [badge.heightAnchor constraintEqualToConstant:26],

        [badgeLabel.centerXAnchor constraintEqualToAnchor:badge.centerXAnchor],
        [badgeLabel.centerYAnchor constraintEqualToAnchor:badge.centerYAnchor],
        [badge.widthAnchor constraintEqualToAnchor:badgeLabel.widthAnchor constant:20],
    ]];

    // ===== حاوية الحالتين =====
    [self buildActivationView];
    [self buildFeaturesView];

    self.activationView.translatesAutoresizingMaskIntoConstraints = NO;
    self.featuresView.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:self.activationView];
    [root addSubview:self.featuresView];

    [NSLayoutConstraint activateConstraints:@[
        [self.activationView.topAnchor constraintEqualToAnchor:topbar.bottomAnchor constant:6],
        [self.activationView.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [self.activationView.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [self.activationView.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],

        [self.featuresView.topAnchor constraintEqualToAnchor:topbar.bottomAnchor constant:6],
        [self.featuresView.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [self.featuresView.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [self.featuresView.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
    ]];

    win.hidden = NO;
    self.panelWindow = win;
    [self refreshStateForActivation];
}

- (void)refreshStateForActivation {
    BOOL activated = [WFActivation isActivated];
    self.activationView.hidden = activated;
    self.featuresView.hidden = !activated;
    if (activated) { [self syncMapWithSavedCoordinate]; }
}

- (void)dismissPanel {
    self.panelWindow.hidden = YES;
}

#pragma mark - حالة 1: شاشة التفعيل

- (void)buildActivationView {
    UIView *v = [UIView new];
    self.activationView = v;

    UIView *lockIcon = [[UIView alloc] init];
    lockIcon.backgroundColor = [WFGold() colorWithAlphaComponent:0.10];
    lockIcon.layer.cornerRadius = 20;
    lockIcon.layer.borderWidth = 1;
    lockIcon.layer.borderColor = [WFGold() colorWithAlphaComponent:0.3].CGColor;
    lockIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [v addSubview:lockIcon];

    UILabel *lockEmoji = [[UILabel alloc] init];
    lockEmoji.text = @"🔒";
    lockEmoji.font = [UIFont systemFontOfSize:28];
    lockEmoji.translatesAutoresizingMaskIntoConstraints = NO;
    [lockIcon addSubview:lockEmoji];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"التفعيل مطلوب";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:16];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [v addSubview:title];

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.text = @"أدخل كود التفعيل للوصول لكل مميزات Fake GPS";
    subtitle.textColor = WFMuted();
    subtitle.font = [UIFont systemFontOfSize:12];
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.numberOfLines = 0;
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    [v addSubview:subtitle];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = WFPanelC();
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.06].CGColor;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [v addSubview:card];

    self.codeField = [[UITextField alloc] init];
    self.codeField.placeholder = @"XXXXXXXX";
    self.codeField.textColor = [UIColor whiteColor];
    self.codeField.font = [UIFont monospacedSystemFontOfSize:18 weight:UIFontWeightBold];
    self.codeField.textAlignment = NSTextAlignmentCenter;
    self.codeField.backgroundColor = WFNavy();
    self.codeField.layer.cornerRadius = 12;
    self.codeField.layer.borderWidth = 1;
    self.codeField.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08].CGColor;
    self.codeField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    self.codeField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.codeField.returnKeyType = UIReturnKeyDone;
    self.codeField.delegate = self;
    self.codeField.translatesAutoresizingMaskIntoConstraints = NO;

    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 44)];
    toolbar.barTintColor = WFPanelC();
    toolbar.translucent = NO;
    toolbar.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"← رجوع"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(dismissKeyboard)];
    backButton.tintColor = WFMuted();
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                  target:nil
                                                                                  action:nil];
    UIBarButtonItem *confirmButton = [[UIBarButtonItem alloc] initWithTitle:@"✓ تأكيد"
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(activateTapped)];
    confirmButton.tintColor = WFGold();
    toolbar.items = @[backButton, flexibleSpace, confirmButton];
    self.codeField.inputAccessoryView = toolbar;
    [card addSubview:self.codeField];

    self.activateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.activateButton setTitle:@"تفعيل" forState:UIControlStateNormal];
    [self.activateButton setTitleColor:WFNavy() forState:UIControlStateNormal];
    self.activateButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    self.activateButton.backgroundColor = WFGold();
    self.activateButton.layer.cornerRadius = 12;
    self.activateButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.activateButton addTarget:self action:@selector(activateTapped) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:self.activateButton];

    self.actStatusLabel = [[UILabel alloc] init];
    self.actStatusLabel.font = [UIFont boldSystemFontOfSize:12];
    self.actStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.actStatusLabel.numberOfLines = 0;
    self.actStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [v addSubview:self.actStatusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [lockIcon.topAnchor constraintEqualToAnchor:v.topAnchor constant:24],
        [lockIcon.centerXAnchor constraintEqualToAnchor:v.centerXAnchor],
        [lockIcon.widthAnchor constraintEqualToConstant:70],
        [lockIcon.heightAnchor constraintEqualToConstant:70],
        [lockEmoji.centerXAnchor constraintEqualToAnchor:lockIcon.centerXAnchor],
        [lockEmoji.centerYAnchor constraintEqualToAnchor:lockIcon.centerYAnchor],

        [title.topAnchor constraintEqualToAnchor:lockIcon.bottomAnchor constant:16],
        [title.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:24],
        [title.trailingAnchor constraintEqualToAnchor:v.trailingAnchor constant:-24],

        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6],
        [subtitle.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:30],
        [subtitle.trailingAnchor constraintEqualToAnchor:v.trailingAnchor constant:-30],

        [card.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:22],
        [card.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:16],
        [card.trailingAnchor constraintEqualToAnchor:v.trailingAnchor constant:-16],

        [self.codeField.topAnchor constraintEqualToAnchor:card.topAnchor constant:18],
        [self.codeField.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [self.codeField.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [self.codeField.heightAnchor constraintEqualToConstant:48],

        [self.activateButton.topAnchor constraintEqualToAnchor:self.codeField.bottomAnchor constant:14],
        [self.activateButton.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [self.activateButton.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18],
        [self.activateButton.heightAnchor constraintEqualToConstant:46],
        [self.activateButton.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18],

        [self.actStatusLabel.topAnchor constraintEqualToAnchor:card.bottomAnchor constant:14],
        [self.actStatusLabel.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:24],
        [self.actStatusLabel.trailingAnchor constraintEqualToAnchor:v.trailingAnchor constant:-24],
    ]];
}

- (void)activateTapped {
    NSString *code = [self.codeField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (code.length < 4) {
        self.actStatusLabel.text = @"أدخل كود صحيح";
        self.actStatusLabel.textColor = WFDanger();
        return;
    }
    self.actStatusLabel.text = @"جاري التحقق...";
    self.actStatusLabel.textColor = WFMuted();
    self.activateButton.enabled = NO;
    [WFActivation activateWithCode:code completion:^(BOOL success, NSString *message) {
        self.actStatusLabel.text = message;
        self.actStatusLabel.textColor = success ? WFSuccess() : WFDanger();
        self.activateButton.enabled = YES;
        if (success) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self refreshStateForActivation];
            });
        }
    }];
}

- (void)dismissKeyboard {
    [self.codeField resignFirstResponder];
}

#pragma mark - حالة 2: شاشة المميزات

- (void)buildFeaturesView {
    UIView *v = [UIView new];
    self.featuresView = v;

    // ===== الخريطة (Hybrid = قمر صناعي مختلط) =====
    self.mapView = [[MKMapView alloc] init];
    self.mapView.mapType = MKMapTypeHybrid;
    self.mapView.layer.cornerRadius = 16;
    self.mapView.clipsToBounds = YES;
    self.mapView.delegate = self;
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    [v addSubview:self.mapView];

    self.pin = [MKPointAnnotation new];
    [self.mapView addAnnotation:self.pin];

    // ===== صف: بحث + مفضلة =====
    UIButton *searchBtn = [self makeFeatureButton:@"🔍  ابحث عن موقع" bg:WFPanelC() textColor:[UIColor whiteColor]];
    [searchBtn addTarget:self action:@selector(searchTapped) forControlEvents:UIControlEventTouchUpInside];

    UIButton *favBtn = [self makeFeatureButton:@"⭐️  المفضلة" bg:[UIColor colorWithRed:0.48 green:0.36 blue:1.0 alpha:1.0] textColor:[UIColor whiteColor]];
    [favBtn addTarget:self action:@selector(favoritesTapped) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *row1 = [[UIStackView alloc] initWithArrangedSubviews:@[searchBtn, favBtn]];
    row1.axis = UILayoutConstraintAxisHorizontal;
    row1.distribution = UIStackViewDistributionFillEqually;
    row1.spacing = 10;
    row1.translatesAutoresizingMaskIntoConstraints = NO;

    // ===== إخفاء زر الأداة =====
    UIButton *hideBtn = [self makeFeatureButton:@"🙈  إخفاء زر الأداة" bg:[UIColor colorWithRed:0.88 green:0.30 blue:0.30 alpha:1.0] textColor:[UIColor whiteColor]];
    [hideBtn addTarget:self action:@selector(hideToolTapped) forControlEvents:UIControlEventTouchUpInside];

    // ===== سويتشات =====
    UIView *toggle1 = [self makeToggleRow:@"تفعيل تغيير الموقع" switchOut:&_moveLocationSwitch];
    UIView *toggle2 = [self makeToggleRow:@"تفعيل الحركة للموقع" switchOut:&_simulateMovementSwitch];
    [self.moveLocationSwitch addTarget:self action:@selector(moveLocationChanged) forControlEvents:UIControlEventValueChanged];
    [self.simulateMovementSwitch addTarget:self action:@selector(movementChanged) forControlEvents:UIControlEventValueChanged];

    // ===== إدارة البلوتوث والبيكونز =====
    UIButton *beaconsBtn = [self makeFeatureButton:@"📶  إدارة البلوتوث والـ Beacons" bg:[UIColor colorWithRed:0.09 green:0.71 blue:0.77 alpha:1.0] textColor:[UIColor whiteColor]];
    [beaconsBtn addTarget:self action:@selector(beaconsTapped) forControlEvents:UIControlEventTouchUpInside];

    // ===== اختر هذا الموقع =====
    UIButton *chooseBtn = [self makeFeatureButton:@"📍  اختر هذا الموقع" bg:WFGold() textColor:WFNavy()];
    [chooseBtn addTarget:self action:@selector(chooseLocationTapped) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[row1, hideBtn, toggle1, toggle2, beaconsBtn, chooseBtn]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [v addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [self.mapView.topAnchor constraintEqualToAnchor:v.topAnchor constant:12],
        [self.mapView.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:16],
        [self.mapView.trailingAnchor constraintEqualToAnchor:v.trailingAnchor constant:-16],
        [self.mapView.heightAnchor constraintEqualToConstant:190],

        [stack.topAnchor constraintEqualToAnchor:self.mapView.bottomAnchor constant:14],
        [stack.leadingAnchor constraintEqualToAnchor:v.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:v.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:v.bottomAnchor constant:-20],
    ]];

    for (UIView *btn in @[searchBtn, favBtn, hideBtn, beaconsBtn, chooseBtn]) {
        [btn.heightAnchor constraintEqualToConstant:44].active = YES;
    }
}

- (UIButton *)makeFeatureButton:(NSString *)title bg:(UIColor *)bg textColor:(UIColor *)textColor {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:textColor forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    b.backgroundColor = bg;
    b.layer.cornerRadius = 12;
    b.translatesAutoresizingMaskIntoConstraints = NO;
    return b;
}

- (UIView *)makeToggleRow:(NSString *)label switchOut:(UISwitch **)switchOut {
    UIView *row = [UIView new];
    row.backgroundColor = WFPanelC();
    row.layer.cornerRadius = 12;
    row.translatesAutoresizingMaskIntoConstraints = NO;
    [row.heightAnchor constraintEqualToConstant:44].active = YES;

    UILabel *l = [[UILabel alloc] init];
    l.text = label;
    l.textColor = [UIColor whiteColor];
    l.font = [UIFont boldSystemFontOfSize:13];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:l];

    UISwitch *sw = [[UISwitch alloc] init];
    sw.onTintColor = WFSuccess();
    sw.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:sw];
    *switchOut = sw;

    [NSLayoutConstraint activateConstraints:@[
        [l.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:14],
        [l.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [sw.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-10],
        [sw.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
    ]];
    return row;
}

#pragma mark - أفعال شاشة المميزات

- (void)searchTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ابحث عن موقع"
        message:@"اكتب اسم المدينة أو المكان" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"مثال: الرياض"; }];
    [alert addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"بحث" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *query = alert.textFields.firstObject.text;
        if (query.length == 0) return;
        CLGeocoder *geocoder = [CLGeocoder new];
        [geocoder geocodeAddressString:query completionHandler:^(NSArray<CLPlacemark *> *placemarks, NSError *error) {
            CLPlacemark *pm = placemarks.firstObject;
            if (pm.location) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self moveMapAndPinTo:pm.location.coordinate];
                });
            }
        }];
    }]];
    [self.panelWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)favoritesTapped {
    // قائمة مواقع محفوظة مسبقاً (Placeholder - يقدر يتوسع لاحقاً بجدول كامل)
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"المفضلة"
        message:@"لا توجد مواقع محفوظة بعد" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"إغلاق" style:UIAlertActionStyleDefault handler:nil]];
    [self.panelWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)hideToolTapped {
    [self hideFloatingButton];
    [self dismissPanel];
}

- (void)moveLocationChanged {
    if (self.moveLocationSwitch.on && ![WFActivation isActivated]) {
        self.moveLocationSwitch.on = NO;
        return;
    }
    [WFActivation setSimulationEnabled:self.moveLocationSwitch.on];
}

- (void)movementChanged {
    // مفتاح "الحركة" منفصل - يُستخدم لاحقاً للتنقل التدريجي بين نقطتين بدل القفز المباشر
    // يُحفظ محلياً فقط في هذا الإصدار
}

- (void)beaconsTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"البلوتوث والـ Beacons"
        message:@"هذه الميزة قيد التطوير وستتوفر في تحديث قادم" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"حسناً" style:UIAlertActionStyleDefault handler:nil]];
    [self.panelWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)chooseLocationTapped {
    CLLocationCoordinate2D coord = self.pin.coordinate;
    [WFActivation saveCoordinate:coord];
    [WFActivation setSimulationEnabled:YES];
    self.moveLocationSwitch.on = YES;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"تم"
        message:@"تم تعيين هذا الموقع وتفعيل المحاكاة" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"حسناً" style:UIAlertActionStyleDefault handler:nil]];
    [self.panelWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - مزامنة الخريطة

- (void)moveMapAndPinTo:(CLLocationCoordinate2D)coord {
    self.pin.coordinate = coord;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord, 4000, 4000);
    [self.mapView setRegion:region animated:YES];
}

- (void)syncMapWithSavedCoordinate {
    CLLocationCoordinate2D coord = [WFActivation savedCoordinate];
    if (coord.latitude == 0 && coord.longitude == 0) {
        coord = CLLocationCoordinate2DMake(24.7136, 46.6753); // الرياض كنقطة افتراضية
    }
    [self moveMapAndPinTo:coord];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == self.codeField) { [self activateTapped]; }
    return YES;
}

@end
