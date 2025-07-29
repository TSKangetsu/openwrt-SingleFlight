include $(TOPDIR)/rules.mk

PKG_NAME:=rtl8812au
PKG_RELEASE=1

PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=

PKG_SOURCE_URL:=https://github.com/lwfinger/rtw88.git
PKG_MIRROR_HASH:=skip
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2025-7-29

PKG_SOURCE_VERSION:=fa96fd4c014fa528d1fa50318e97aa71bf4f473c
PKG_BUILD_PARALLEL:=1

STAMP_CONFIGURED_DEPENDS := $(STAGING_DIR)/usr/include/mac80211-backport/backport/autoconf.h

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define KernelPackage/rtl8812au
  SUBMENU:=Wireless Drivers
  TITLE:=Driver for Realtek 8812 AU devices from aircrack
  DEPENDS:=+kmod-mac80211 +kmod-usb-core +@DRIVER_11AC_SUPPORT +@KERNEL_PAGE_POOL
  FILES:=$(PKG_BUILD_DIR)/rtw_8812au.ko \
		 $(PKG_BUILD_DIR)/rtw_8812a.ko \
		 $(PKG_BUILD_DIR)/rtw_usb.ko \
		 $(PKG_BUILD_DIR)/rtw_88xxa.ko \
		 $(PKG_BUILD_DIR)/rtw_core.ko 
  AUTOLOAD:=$(call AutoProbe,rtw_core rtw_88xxa rtw_usb rtw_8812a rtw_8812au)
endef

NOSTDINC_FLAGS := \
	$(KERNEL_NOSTDINC_FLAGS) \
	-I$(PKG_BUILD_DIR)

NOSTDINC_FLAGS+=-DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT -DBUILD_OPENWRT

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C "$(LINUX_DIR)" \
		$(KERNEL_MAKE_FLAGS) \
		M="$(PKG_BUILD_DIR)" \
		NOSTDINC_FLAGS="$(NOSTDINC_FLAGS)" \
		modules
endef

$(eval $(call KernelPackage,rtl8812au))