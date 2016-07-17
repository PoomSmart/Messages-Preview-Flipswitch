TARGET = iphone:latest
DEBUG = 0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MPFS
MPFS_FILES = Switch.xm
MPFS_FRAMEWORKS = UIKit
MPFS_PRIVATE_FRAMEWORKS = BulletinBoard Preferences
MPFS_LIBRARIES = flipswitch
MPFS_INSTALL_PATH = /Library/Switches

include $(THEOS_MAKE_PATH)/bundle.mk