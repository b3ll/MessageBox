GO_EASY_ON_ME = 1
THEOS_DEVICE_IP = 10.0.2.10
THEOS_DEVICE_PORT = 22

TARGET = iphone:clang:latest:7.0
ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

TWEAK_NAME = messagebox
messagebox_CFLAGS = -fobjc-arc -IXcode-Theos
messagebox_FILES = MBChatHeadWindow.m Tweak.xmi
messagebox_LIBRARIES = substrate rocketbootstrap
messagebox_FRAMEWORKS = Foundation CoreGraphics QuartzCore UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += messageboxpreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
