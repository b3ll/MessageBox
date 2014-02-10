GO_EASY_ON_ME = 1
THEOS_DEVICE_IP = 127.0.0.1
THEOS_DEVICE_PORT = 2222

ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

TWEAK_NAME = messagebox
messagebox_CFLAGS = -fobjc-arc
messagebox_FILES = MBChatHeadWindow.m Tweak.xmi
messagebox_LIBRARIES = substrate
messagebox_FRAMEWORKS = Foundation QuartzCore UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Paper"
