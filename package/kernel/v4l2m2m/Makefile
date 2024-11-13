include $(TOPDIR)/rules.mk

PKG_NAME:=v4l2m2mpasser
PKG_RELEASE=1

PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=

PKG_SOURCE_URL:=https://github.com/TSKangetsu/v4l2m2m
PKG_MIRROR_HASH:=skip
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2024-11-11

PKG_SOURCE_VERSION:=ff7c03e82471411b5d9b7245af772faa2dc95245
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define KernelPackage/v4l2m2mpasser
	SUBMENU:=Video Support
	DEPENDS:=+kmod-video-videobuf2
	TITLE:=Driver for v4l2 user space img exchange
	FILES:=$(PKG_BUILD_DIR)/v4l2m2m.ko
	AUTOLOAD:=$(call AutoProbe,v4l2m2m)
endef

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C "$(LINUX_DIR)" \
		$(KERNEL_MAKE_FLAGS) \
		M="$(PKG_BUILD_DIR)" \
		modules
endef

$(eval $(call KernelPackage,v4l2m2mpasser))