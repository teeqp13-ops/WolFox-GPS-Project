# WolFox GPS Tweak - مشروع متكامل

## المشروع يتضمن:

### 1. Backend (سيرفر التفعيل)
- `backend/config.php` - إعدادات الاتصال والـ HMAC
- `backend/api.php` - API التفعيل
- `backend/admin/` - لوحة التحكم

### 2. Theos Project (بناء الـ Tweak)
- `theos/Tweak.xm` - الـ hooks الرئيسية
- `theos/WFActivation.mm` - منطق التفعيل
- `theos/WFGPSPanel.mm` - الزر العائم
- `theos/Makefile` - ملف البناء
- `theos/control` - معلومات الحزمة

### 3. iOS Integration
- ملفات للدمج في تطبيق iOS

### 4. Documentation
- أدلة التثبيت والاستخدام
