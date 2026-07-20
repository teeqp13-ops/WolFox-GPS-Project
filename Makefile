ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = BYANO

BYANO_FILES = c.mm KSA.mm fishhook/fishhook.c
BYANO_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value -Wno-enum-conversion
BYANO_CCFLAGS = -std=c++17 -fno-rtti -fno-exceptions
BYANO_FRAMEWORKS = UIKit Foundation MetalKit Metal ModelIO Security QuartzCore CoreGraphics CoreText AudioToolbox AVFoundation Accelerate Photos MediaPlayer CoreAudio

include $(THEOS_MAKE_PATH)/library.mk
