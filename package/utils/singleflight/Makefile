include $(TOPDIR)/rules.mk

PKG_NAME:=singleflight
PKG_LICENSE:=GPLv3
PKG_SOURCE_URL:=https://github.com/TSKangetsu/RPiSingleAPM
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2024-5-7
PKG_SOURCE_VERSION:=5b86cb54665907712962d1f5a8a622d949985fe8
PKG_MIRROR_HASH:=skip
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_OPTIONS+= \
	-DOPENWRT=TRUE

define Package/singleflight
	SECTION:=utils
  	CATEGORY:=Utilities
	DEPENDS:=+kmod-spi-dev +kmod-i2c-core
	TITLE:=Linux flight controller
	VERSION:=$(LINUX_VERSION)-$(PKG_SOURCE_DATE)
endef

define Package/singleflight/description
	Linux flight controller
endef

define Build/Install
endef

define Package/singleflight/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/SingleFlight $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/APMconfig.json $(1)/etc/
endef

$(eval $(call BuildPackage,singleflight))