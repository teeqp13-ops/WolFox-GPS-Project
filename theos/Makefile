ARCHS = arm64
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WolFoxGPS
WolFoxGPS_FILES = Tweak.xm WFActivation.mm WFGPSPanel.mm ios/WFActivationViewController.m
WolFoxGPS_CFLAGS = -fobjc-arc
WolFoxGPS_FRAMEWORKS = UIKit CoreLocation MapKit Security

include $(THEOS_MAKE_PATH)/tweak.mk
