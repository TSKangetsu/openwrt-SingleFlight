# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2013-2016 OpenWrt.org
# Copyright (C) 2016 Yousong Zhou

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

FAT32_BLOCK_SIZE=1024
FAT32_BLOCKS=$(shell echo $$(($(CONFIG_SUNXI_SD_BOOT_PARTSIZE)*1024*1024/$(FAT32_BLOCK_SIZE))))

DEVICE_VARS := SUNXI_DTS SUNXI_DTS_DIR
KERNEL_LOADADDR:=0x40008000

define Build/Compile
	@cp $(TOPDIR)/target/linux/sunxi/dts/suniv-f1c100s-licheepi-nano.dts $(LINUX_DIR)/arch/arm/boot/dts/suniv-f1c100s-licheepi-nano.dts
	@cp $(TOPDIR)/target/linux/sunxi/dts/suniv-f1c100s.dtsi $(LINUX_DIR)/arch/arm/boot/dts/suniv-f1c100s.dtsi
	@cp $(TOPDIR)/target/linux/sunxi/dts/sun8i-h3-nanopi-neo-air.dts $(LINUX_DIR)/arch/arm/boot/dts/sun8i-h3-nanopi-neo-air.dts
endef

define Build/sunxi-sdcard
	rm -f $@.boot
	mkfs.fat $@.boot -C $(FAT32_BLOCKS)

	mcopy -i $@.boot $(STAGING_DIR_IMAGE)/$(DEVICE_NAME)-boot.scr ::boot.scr
	mcopy -i $@.boot $(DTS_DIR)/$(SUNXI_DTS).dtb ::dtb
	mcopy -i $@.boot $(IMAGE_KERNEL) ::uImage
	./gen_sunxi_sdcard_img.sh $@ \
		$@.boot \
		$(IMAGE_ROOTFS) \
		$(CONFIG_SUNXI_SD_BOOT_PARTSIZE) \
		$(CONFIG_TARGET_ROOTFS_PARTSIZE) \
		$(STAGING_DIR_IMAGE)/$(DEVICE_NAME)-u-boot-with-spl.bin
	rm -f $@.boot
endef

define Build/sunxi-sdcard-zImage
	rm -f $@.boot
	mkfs.fat $@.boot -C $(FAT32_BLOCKS)

	mcopy -i $@.boot $(STAGING_DIR_IMAGE)/$(DEVICE_NAME)-boot.scr ::boot.scr
	mcopy -i $@.boot $(DTS_DIR)/$(SUNXI_DTS).dtb ::dtb
	
	mcopy -i $@.boot $(KERNEL_BUILD_DIR)/zImage ::zImage

	./gen_sunxi_sdcard_img.sh $@ \
		$@.boot \
		$(IMAGE_ROOTFS) \
		$(CONFIG_SUNXI_SD_BOOT_PARTSIZE) \
		$(CONFIG_TARGET_ROOTFS_PARTSIZE) \
		$(STAGING_DIR_IMAGE)/$(DEVICE_NAME)-u-boot-with-spl.bin
	rm -f $@.boot
endef

# why \x00\x00\x00\x00 for zImage-initramfs
define Device/Default
  PROFILES := Default
  KERNEL_NAME := zImage
  KERNEL := kernel-bin | uImage none
  IMAGES := sdcard.img.gz
  IMAGE/sdcard.img.gz := sunxi-sdcard | append-metadata | gzip
  SUNXI_DTS_DIR :=
  SUNXI_DTS = $$(SUNXI_DTS_DIR)$$(SOC)-$(lastword $(subst _, ,$(1)))
endef

include $(SUBTARGET).mk

$(eval $(call BuildImage))
