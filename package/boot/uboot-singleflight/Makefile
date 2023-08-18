#
# Copyright (C) 2013-2016 OpenWrt.org
# Copyright (C) 2017 Yousong Zhou
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_VERSION:=2022.10

PKG_HASH:=skip

PKG_MAINTAINER:=Zoltan HERPAI <wigyori@uid0.hu>

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk

define U-Boot/Default
  HIDDEN:=1
endef

define U-Boot/licheepi_nano
  BUILD_TARGET:=singleflight
  UBOOT_IMAGE:=u-boot-sunxi-with-spl.bin
  BUILD_SUBTARGET:=arm9
  NAME:=Licheepi Nano
  UENV:=arm9
  BUILD_DEVICES:=singleflight_flash_licheepi-nano
endef

UBOOT_TARGETS := \
  licheepi_nano

UBOOT_CONFIGURE_VARS += USE_PRIVATE_LIBGCC=yes

UBOOT_MAKE_FLAGS += \
	BL31=$(STAGING_DIR_IMAGE)/bl31_sun50i_$(ATF).bin

define Build/Configure
  $(call Build/Configure/U-Boot)
  $(info [DEBUG] adding boot cmd)
  # sed -i 's/CONFIG_TOOLS_LIBCRYPTO=y/# CONFIG_TOOLS_LIBCRYPTO is not set/' $(PKG_BUILD_DIR)/.config
  $(shell sed -i 's/CONFIG_BOOTCOMMAND="sf probe 0 50000000; sf read 0x80C00000 0x100000 0x4000; sf read 0x80500000 0x110000 0x400000; bootz 0x80500000 - 0x80C00000"/CONFIG_BOOTCOMMAND="run distro_bootcmd"/' $(PKG_BUILD_DIR)/.config)
  $(shell sed -i 's/CONFIG_USE_BOOTARGS="console=ttyS0,115200 earlyprintk panic=5 rootwait; mtdparts=spi32766.0:1M(uboot)ro,64k(dtb)ro,4M(kernel)ro,-(rootfs) root=/dev/mtdblock3 rw rootfstype=jffs2"/# CONFIG_USE_BOOTARGS is not set/' $(PKG_BUILD_DIR)/.config)
endef

define Build/InstallDev
  $(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	$(CP) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(STAGING_DIR_IMAGE)/$(BUILD_DEVICES)-u-boot-with-spl.bin
	mkimage -C none -A arm -T script -d uEnv-$(UENV).txt \
		$(STAGING_DIR_IMAGE)/$(BUILD_DEVICES)-boot.scr
endef

define Package/u-boot/install/default
endef

$(eval $(call BuildPackage/U-Boot))
