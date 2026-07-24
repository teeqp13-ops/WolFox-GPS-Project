.PHONY: all build package install clean help

# متغيرات المشروع
PROJECT_NAME = WolFox GPS Tweak
VERSION = 1.0.0
PACKAGE_NAME = com.wolfox.gpstweak

# المسارات
THEOS_PATH = theos
BACKEND_PATH = backend
DOCS_PATH = docs

# الألوان
GREEN = \033[0;32m
BLUE = \033[0;34m
YELLOW = \033[0;33m
NC = \033[0m # No Color

help:
@echo "$(BLUE)╔════════════════════════════════════════╗$(NC)"
@echo "$(BLUE)║  WolFox GPS Tweak - Build System       ║$(NC)"
@echo "$(BLUE)╚════════════════════════════════════════╝$(NC)"
@echo ""
@echo "$(YELLOW)Available targets:$(NC)"
@echo "  $(GREEN)make build$(NC)      - بناء الـ Tweak"
@echo "  $(GREEN)make package$(NC)    - إنشاء حزمة deb"
@echo "  $(GREEN)make install$(NC)    - تثبيت على الجهاز"
@echo "  $(GREEN)make clean$(NC)      - حذف ملفات البناء"
@echo "  $(GREEN)make help$(NC)       - عرض هذه الرسالة"
@echo ""

build:
@echo "$(BLUE)[*] Building $(PROJECT_NAME) v$(VERSION)...$(NC)"
@cd $(THEOS_PATH) && $(MAKE)
@echo "$(GREEN)[✓] Build completed!$(NC)"

package:
@echo "$(BLUE)[*] Creating deb package...$(NC)"
@cd $(THEOS_PATH) && $(MAKE) package
@echo "$(GREEN)[✓] Package created!$(NC)"

install:
@echo "$(BLUE)[*] Installing on device...$(NC)"
@cd $(THEOS_PATH) && $(MAKE) install
@echo "$(GREEN)[✓] Installation completed!$(NC)"

clean:
@echo "$(BLUE)[*] Cleaning build files...$(NC)"
@if [ -d "$(THEOS_PATH)" ] && [ -f "$(THEOS_PATH)/Makefile" ]; then \
cd $(THEOS_PATH) && $(MAKE) clean || true; \
fi
@rm -rf artifacts/ .theos/ _/ packages/
@echo "$(GREEN)[✓] Cleaned!$(NC)"

all: build package
@echo "$(GREEN)[✓] All done!$(NC)"
