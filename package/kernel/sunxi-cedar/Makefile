include $(TOPDIR)/rules.mk

PKG_NAME:=sunxi-cedar
PKG_RELEASE=1

PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=

PKG_SOURCE_URL:=https://github.com/TSKangetsu/sunxi-cedar-mainline
PKG_MIRROR_HASH:=skip
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2024-7-24

PKG_SOURCE_VERSION:=3c1596644695c7adf00aeb35144f1459b307b16f
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define KernelPackage/sunxi-cedar
	SUBMENU:=Video Support
	TITLE:=Driver for sunxi de/encoder device cedar_dev
	DEPENDS:=@TARGET_sunxi +kmod-cma-buf
	FILES:=$(PKG_BUILD_DIR)/cedar_ve.ko
	AUTOLOAD:=$(call AutoProbe,cedar_ve)
endef

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C "$(LINUX_DIR)" \
		$(KERNEL_MAKE_FLAGS) \
		M="$(PKG_BUILD_DIR)" \
		modules
endef

$(eval $(call KernelPackage,sunxi-cedar))