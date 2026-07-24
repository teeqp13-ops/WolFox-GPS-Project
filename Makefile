.PHONY: all build package install clean

PROJECT_NAME = WolFox GPS Tweak
VERSION = 1.0.0
PACKAGE_NAME = com.wolfox.gpstweak

THEOS_PATH = theos
BACKEND_PATH = backend
DOCS_PATH = docs

build:
	@echo "[*] Building $(PROJECT_NAME) v$(VERSION)..."
	@cd $(THEOS_PATH) && $(MAKE)
	@echo "[✓] Build completed!"

package:
	@echo "[*] Creating deb package..."
	@$(MAKE) -C $(THEOS_PATH) package
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
