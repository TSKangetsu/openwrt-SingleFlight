#
# Copyright (C) 2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=linux-firmware-radxa
PKG_VERSION:=2023-8-24
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/pyavitz/firmware
PKG_SOURCE_VERSION:=c2ea7658ae8b8b56f4da6e8d136c9e3170babfe2
PKG_MIRROR_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/radxa-firmware-default
  SECTION:=firmware
  CATEGORY:=Firmware
  URL:=$(PKG_SOURCE_URL)
  TITLE:=Broadcom BCM43456 firmware
endef

define Build/Compile
  true
endef

define Package/radxa-firmware-43456-sdio-radxa-rockpi4b
  $(Package/radxa-firmware-default)
  TITLE:=radxa rockpi4b BCM43456 firmware
endef

define Package/radxa-firmware-43456-sdio-radxa-rockpi4b/install
	$(INSTALL_DIR) $(1)/lib/firmware/brcm
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/brcm/brcmfmac43456-sdio.bin \
		$(1)/lib/firmware/brcm/brcmfmac43456-sdio.bin
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/brcm/brcmfmac43456-sdio.txt \
		$(1)/lib/firmware/brcm/brcmfmac43456-sdio.txt
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/brcm/brcmfmac43456-sdio.clm_blob \
		$(1)/lib/firmware/brcm/brcmfmac43456-sdio.clm_blob
endef
$(eval $(call BuildPackage,radxa-firmware-43456-sdio-radxa-rockpi4b))
