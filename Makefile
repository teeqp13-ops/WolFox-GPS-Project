.PHONY: all build package install clean

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


build:
	@echo "[*] Building $(PROJECT_NAME) v$(VERSION)..."
	@cd $(THEOS_PATH) && $(MAKE)
	@echo "[✓] Build completed!"

package:
	@echo "[*] Creating deb package..."
	@cd $(THEOS_PATH) && make package
	@echo "[✓] Package created!"

install:
	@echo "[*] Installing on device..."
	@cd $(THEOS_PATH) && $(MAKE) install
	@echo "[✓] Installation completed!"

clean:
	@echo "[*] Cleaning build files..."
	@if [ -d "$(THEOS_PATH)" ] && [ -f "$(THEOS_PATH)/Makefile" ]; then \
		cd $(THEOS_PATH) && $(MAKE) clean || true; \
	fi
	@rm -rf artifacts/ .theos/ _/ packages/
	@echo "[✓] Cleaned!"

all: build package
	@echo "[✓] All done!"
