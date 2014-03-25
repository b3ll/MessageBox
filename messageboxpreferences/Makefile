GO_EASY_ON_ME=1

TARGET = iphone:clang:latest:7.0
ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

BUNDLE_NAME = messageboxpreferences
messageboxpreferences_FILES = messageboxpreferences.mm
messageboxpreferences_INSTALL_PATH = /Library/PreferenceBundles
messageboxpreferences_FRAMEWORKS = UIKit
messageboxpreferences_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/messageboxpreferences.plist$(ECHO_END)
