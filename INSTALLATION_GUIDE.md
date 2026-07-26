# 🚀 WolFox GPS Tweak - دليل التثبيت والاستخدام الشامل

## 📋 المحتويات

1. [نظرة عامة](#نظرة-عامة)
2. [المتطلبات](#المتطلبات)
3. [التثبيت](#التثبيت)
4. [الاستخدام](#الاستخدام)
5. [استكشاف الأخطاء](#استكشاف-الأخطاء)

---

## 🎯 نظرة عامة

**WolFox GPS Tweak** هو أداة متقدمة لمحاكاة موقع GPS على مستوى النظام مع:
- ✅ زر عائم للتحكم السهل
- ✅ نظام تفعيل آمن مع سيرفر خاص
- ✅ دعم جميع التطبيقات
- ✅ واجهة احترافية

---

## 📦 المتطلبات

### للجهاز (iPhone):
- ✅ iOS 14.0 أو أحدث
- ✅ جهاز مجيل (Jailbroken)
- ✅ Substrate أو Substitute
- ✅ اتصال إنترنت

### للسيرفر:
- ✅ استضافة ويب (PHP 7.4+)
- ✅ قاعدة بيانات SQLite
- ✅ صلاحيات الكتابة (755/775)

### للبناء (على Mac):
- ✅ Theos مثبت
- ✅ Xcode Command Line Tools
- ✅ LLVM Toolchain

---

## 🔧 التثبيت

### الخطوة 1: إعداد السيرفر

```bash
# 1. انسخ مجلد backend إلى السيرفر
scp -r backend/ user@server:/var/www/activate.example.com/

# 2. اجعل المجلد قابل للكتابة
chmod 755 /var/www/activate.example.com/backend/

# 3. عدّل config.php
nano /var/www/activate.example.com/backend/config.php
# غيّر:
# اضبط متغيرات البيئة في الاستضافة:
# - WOLFOX_ADMIN_PASSWORD (كلمة مرور لوحة الإدارة)
# - OPENAI_API_KEY (اختياري لصفحة المساعد)
# - لا تضف أي مفتاح سري لتطبيق iOS
```

### الخطوة 2: بناء الـ Tweak (على Mac)

```bash
# 1. انسخ مجلد theos
cd theos/

# 2. عدّل Makefile إذا لزم الأمر
nano Makefile

# 3. بناء الـ Tweak
make

# 4. إنشاء الحزمة
make package

# 5. تثبيت على الجهاز (اختياري)
make install THEOS_DEVICE_IP=192.168.1.100
```

### الخطوة 3: التثبيت على الجهاز

#### الطريقة 1: عبر Cydia/Sileo
```
1. فتح Cydia أو Sileo
2. أضف المستودع: https://repo.example.com/
3. ابحث عن "WolFox GPS"
4. اضغط Install
5. أعد تشغيل Springboard
```

#### الطريقة 2: عبر SSH
```bash
scp com.wolfox.gpstweak_1.0_iphoneos-arm64.deb root@device:/tmp/
ssh root@device "dpkg -i /tmp/com.wolfox.gpstweak_1.0_iphoneos-arm64.deb && killall -9 SpringBoard"
```

#### الطريقة 3: عبر Filza
```
1. نسخ الملف إلى الجهاز
2. فتح Filza
3. اختيار الملف → Install
4. تأكيد التثبيت
5. إعادة تشغيل Springboard
```

---

## 📱 الاستخدام

### التفعيل الأول

```
1. بعد التثبيت، سيظهر زر عائم على الشاشة
2. اضغط على الزر → "تفعيل"
3. أدخل كود التفعيل (8 أحرف)
4. اضغط "تفعيل الآن"
5. انتظر 2-3 ثواني
6. ✅ تم التفعيل بنجاح!
```

### الحصول على كود التفعيل

```
1. اذهب إلى لوحة التحكم:
   https://activate.example.com/admin/

2. استخدم قيمة WOLFOX_ADMIN_PASSWORD التي ضبطتها في بيئة الخادم

3. اضغط "توليد أكواد"

4. أدخل عدد الأكواد (1-100)

5. اختر مدة الصلاحية (اختياري)

6. اضغط "توليد"

7. انسخ الكود
```

### استخدام الأداة

```
1. اضغط على الزر العائم
2. اختر "تعديل الموقع"
3. اختر موقع من الخريطة أو أدخل الإحداثيات
4. اضغط "حفظ"
5. فعّل "محاكاة الموقع"
6. الآن جميع التطبيقات ستستخدم الموقع المزيف
```

---

## 🐛 استكشاف الأخطاء

### المشكلة: الزر العائم لا يظهر

**الحل:**
```bash
# أعد تشغيل Springboard
ssh root@device "killall -9 SpringBoard"

# أو أعد تشغيل الجهاز بالكامل
ssh root@device "reboot"
```

### المشكلة: فشل التفعيل

**الحل:**
```bash
# تحقق من اتصال الإنترنت
ping activate.example.com

# تحقق من السيرفر
curl https://activate.example.com/api.php

# تحقق من WOLFOX_ADMIN_PASSWORD في إعدادات بيئة الخادم
# لا تستخدم مفاتيح HMAC مشتركة داخل التطبيق
```

### المشكلة: الموقع لا يتغير

**الحل:**
```
1. تأكد من تفعيل "محاكاة الموقع"
2. أغلق التطبيق وأعد فتحه
3. تحقق من صلاحيات الموقع في Settings
4. أعد تشغيل Springboard
```

### المشكلة: لا يمكن الوصول إلى لوحة التحكم

**الحل:**
```bash
# تحقق من صلاحيات المجلد
chmod 755 /var/www/activate.example.com/backend/

# تحقق من ملف config.php
cat /var/www/activate.example.com/backend/config.php

# تحقق من قاعدة البيانات
ls -la /var/www/activate.example.com/backend/database.sqlite
```

---

## 📊 معلومات تقنية

### Dylib Specifications:
- **Type**: Mach-O 64-bit arm64
- **Size**: 900 KB
- **Segments**: PAGEZERO, TEXT, DATA, LINKEDIT
- **Status**: Production Ready

### API Endpoints:
- **Activation**: `POST /api.php`
- **Verification**: `POST /api.php?action=verify`
- **Admin**: `https://activate.example.com/admin/`

### Database Schema:
```sql
CREATE TABLE codes (
    id INTEGER PRIMARY KEY,
    code TEXT UNIQUE,
    device_id TEXT,
    status TEXT,
    created_at DATETIME,
    expires_at DATETIME
);
```

---

## 🔐 الأمان

- ✅ تشفير SSL/TLS للاتصالات
- ✅ لا توجد أسرار مشتركة مضمنة في العميل
- ✅ التحقق من مدخلات التفعيل على الخادم
- ✅ حماية من هجمات التكرار

---

## 📞 الدعم

للمساعدة والدعم الفني:
- 📧 البريد الإلكتروني: support@wolfox.dev
- 🌐 الموقع: https://wolfoxdash-9n8qfpkx.manus.space
- 📱 الهاتف: +966 (متاح قريباً)

---

**Version**: 1.0.0
**Last Updated**: July 2024
**Status**: Production Ready ✅

**استمتع بـ WolFox GPS Tweak!** 🚀
