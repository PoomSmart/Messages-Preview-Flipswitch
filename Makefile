SDKVERSION = 7.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk

BUNDLE_NAME = MPFS
MPFS_FILES = Switch.xm
MPFS_FRAMEWORKS = UIKit
MPFS_PRIVATEFRAMEWORKS = ManagedConfiguration
MPFS_LIBRARIES = flipswitch
MPFS_INSTALL_PATH = /Library/Switches

include $(THEOS_MAKE_PATH)/bundle.mk