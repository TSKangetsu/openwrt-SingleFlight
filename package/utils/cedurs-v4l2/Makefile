include $(TOPDIR)/rules.mk

PKG_NAME:=cedurs-v4l2
PKG_LICENSE:=GPLv3
PKG_SOURCE_URL:=https://github.com/TSKangetsu/cedurs264-libav2v4l2
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2024-11-13
PKG_SOURCE_VERSION:=e6888a4cdc14e91bca8aa8164f77c787626e0873
PKG_MIRROR_HASH:=skip
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

# CMAKE_OPTIONS+= \
# 	-G "Unix Makefiles"

define Package/cedurs-v4l2
	SECTION:=utils
  	CATEGORY:=Utilities
	TITLE:=sunxi h264 encoder
	VERSION:=$(LINUX_VERSION)-$(PKG_SOURCE_DATE)
endef

define Package/cedurs-v4l2/description
	sunxi h3 cedurs v4l2 m2m h264 encoder driver
endef

define Build/Install
endef

define Package/cedurs-v4l2/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/v4l2-cedurs $(1)/usr/bin
endef

$(eval $(call BuildPackage,cedurs-v4l2))