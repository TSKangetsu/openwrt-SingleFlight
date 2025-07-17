include $(TOPDIR)/rules.mk

PKG_NAME:=aic8800d
PKG_RELEASE=5

PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=

PKG_SOURCE_URL:=https://github.com/TSKangetsu/aic8800dback
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2024-11-19

PKG_SOURCE_VERSION:=48ab8457fa8b25589295416aaee748703643885b
PKG_MIRROR_HASH:=skip

STAMP_CONFIGURED_DEPENDS := $(STAGING_DIR)/usr/include/mac80211-backport/backport/autoconf.h

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define KernelPackage/aic8800d
  SUBMENU:=Wireless Drivers
  TITLE:=Driver for AIC8800d d80 d80x2
  DEPENDS:= \
		+kmod-cfg80211 \
		+@DRIVER_11AC_SUPPORT +@DRIVER_11N_SUPPORT
	FILES:=$(PKG_BUILD_DIR)/aic8800_bsp/aic8800_bsp.ko \
			$(PKG_BUILD_DIR)/aic8800_btlpm/aic8800_btlpm.ko \
			$(PKG_BUILD_DIR)/aic8800_fdrv/aic8800_fdrv.ko
	AUTOLOAD:=$(call AutoProbe,aic8800_bsp.ko,aic8800_fdrv.ko)
endef

NOSTDINC_FLAGS := \
	$(KERNEL_NOSTDINC_FLAGS) \
	-I$(PKG_BUILD_DIR) \
	-I$(PKG_BUILD_DIR)/include \
	-I$(STAGING_DIR)/usr/include/mac80211-backport \
	-I$(STAGING_DIR)/usr/include/mac80211-backport/uapi \
	-I$(STAGING_DIR)/usr/include/mac80211 \
	-I$(STAGING_DIR)/usr/include/mac80211/uapi \
	-include backport/backport.h

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C "$(LINUX_DIR)" \
		$(KERNEL_MAKE_FLAGS) \
		M="$(PKG_BUILD_DIR)" \
		NOSTDINC_FLAGS="$(NOSTDINC_FLAGS)" \
		modules
endef

$(eval $(call KernelPackage,aic8800d))