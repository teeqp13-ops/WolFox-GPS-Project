export THEOS = /home/ubuntu/theos

ROOTLESS = 1

ifeq ($(ROOTLESS),1)
THEOS_PACKAGE_SCHEME = rootless
endif

ifeq ($(ROOTLESS),2)
THEOS_PACKAGE_SCHEME = roothide
endif

THEOS_IGNORE_DEPRECATED = 1

TARGET = iphone:clang:latest:16.5
ARCHS = arm64

LIBRARY_NAME = BYANO
BYANO_STATIC = 1

PROJ_COMMON_FRAMEWORKS = UIKit Foundation MetalKit Metal ModelIO Security QuartzCore CoreGraphics CoreText AudioToolbox AVFoundation Accelerate Photos MediaPlayer CoreAudio

BYANO_FILES = \
c.mm \
KSA.mm \
fishhook/fishhook.c 

BYANO_CFLAGS = \
-fobjc-arc \
-Wno-deprecated-declarations \
-Wno-unused-variable \
-Wno-unused-value \
-Wno-enum-conversion

BYANO_CXXFLAGS = \
-std=c++14 \
-fno-rtti \
-fno-exceptions

BYANO_FRAMEWORKS = $(PROJ_COMMON_FRAMEWORKS)


include $(THEOS_MAKE_PATH)/library.mk