# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2013-2016 OpenWrt.org

include $(TOPDIR)/rules.mk

ARCH:=arm
BOARD:=singleflight
BOARDNAME:=SingleFlight Allwinner F1SCx00
SUBTARGETS:=arm9
FEATURES:=usb ext4 display rootfs-part rtc squashfs

KERNEL_PATCHVER:=5.10

KERNELNAME:=zImage dtbs

include $(INCLUDE_DIR)/target.mk

DEFAULT_PACKAGES += uboot-envtools
DEFAULT_PACKAGES += partx-utils mkf2fs e2fsprogs

$(eval $(call BuildTarget))
