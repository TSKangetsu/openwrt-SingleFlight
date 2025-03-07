# SPDX-License-Identifier: GPL-2.0-only
# 
# Copyright (C) 2013-2016 OpenWrt.org

define KernelPackage/usb-sunxi-mbus
    SUBMENU:=$(USB_MENU)
    TITLE:=SUN6I SoC MBUS
    DEPENDS:=@TARGET_sunxi +kmod-usb-gadget +kmod-usb-dwc2
    KCONFIG:=CONFIG_USB_PHY=y \
             CONFIG_USB_DWC2_DUAL_ROLE=y \
             CONFIG_USB_DWC2_PERIPHERAL=n \
             CONFIG_USB_GADGET_VBUS_DRAW=500 \
             CONFIG_USB_MUSB_HDRC \
             CONFIG_USB_MUSB_GADGET=n \
             CONFIG_USB_MUSB_HOST=n \
             CONFIG_USB_MUSB_DUAL_ROLE=y \
             CONFIG_USB_MUSB_SUNXI
    FILES:=$(LINUX_DIR)/drivers/usb/musb/sunxi.ko \
           $(LINUX_DIR)/drivers/usb/musb/musb_hdrc.ko
    AUTOLOAD:=$(call AutoLoad,50,musb_hdrc sunxi)
endef

define KernelPackage/usb-sunxi-mbus/description
 Support for the AllWinner sunXi MBUS Driver
endef

$(eval $(call KernelPackage,usb-sunxi-mbus))

define KernelPackage/sunxi-csi
    TITLE:=SUN6I SoC CSI
    SUBMENU:=$(VIDEO_MENU)
    DEPENDS:=@TARGET_sunxi +kmod-video-core +kmod-video-videobuf2
    KCONFIG:= CONFIG_VIDEO_SUN4I_CSI=n \
              CONFIG_VIDEO_SUN8I_DEINTERLACE=n \
              CONFIG_VIDEO_SUN8I_ROTATE=n \
              CONFIG_VIDEO_SUN6I_CSI
              
    FILES:=$(LINUX_DIR)/drivers/media/platform/sunxi/sun6i-csi/sun6i-csi.ko
    AUTOLOAD:=$(call AutoLoad,70,sun6i-csi)
endef

define KernelPackage/sunxi-csi/description
 Support for the AllWinner sunXi SoC's CSI mipi port
endef

$(eval $(call KernelPackage,sunxi-csi))

define KernelPackage/rtc-sunxi
    SUBMENU:=$(OTHER_MENU)
    TITLE:=Sunxi SoC built-in RTC support
    DEPENDS:=@TARGET_sunxi
    $(call AddDepends/rtc)
    KCONFIG:= \
	CONFIG_RTC_DRV_SUNXI \
	CONFIG_RTC_CLASS=y
    FILES:=$(LINUX_DIR)/drivers/rtc/rtc-sunxi.ko
    AUTOLOAD:=$(call AutoLoad,50,rtc-sunxi)
endef

define KernelPackage/rtc-sunxi/description
 Support for the AllWinner sunXi SoC's onboard RTC
endef

$(eval $(call KernelPackage,rtc-sunxi))

define KernelPackage/sunxi-ir
    SUBMENU:=$(OTHER_MENU)
    TITLE:=Sunxi SoC built-in IR support (A20)
    DEPENDS:=@TARGET_sunxi +kmod-input-core
    $(call AddDepends/rtc)
    KCONFIG:= \
	CONFIG_MEDIA_SUPPORT=y \
	CONFIG_MEDIA_RC_SUPPORT=y \
	CONFIG_RC_DEVICES=y \
	CONFIG_IR_SUNXI
    FILES:=$(LINUX_DIR)/drivers/media/rc/sunxi-cir.ko
    AUTOLOAD:=$(call AutoLoad,50,sunxi-cir)
endef

define KernelPackage/sunxi-ir/description
 Support for the AllWinner sunXi SoC's onboard IR (A20)
endef

$(eval $(call KernelPackage,sunxi-ir))

define KernelPackage/ata-sunxi
    TITLE:=AllWinner sunXi AHCI SATA support
    SUBMENU:=$(BLOCK_MENU)
    DEPENDS:=@TARGET_sunxi +kmod-ata-ahci-platform +kmod-scsi-core
    KCONFIG:=CONFIG_AHCI_SUNXI
    FILES:=$(LINUX_DIR)/drivers/ata/ahci_sunxi.ko
    AUTOLOAD:=$(call AutoLoad,41,ahci_sunxi,1)
endef

define KernelPackage/ata-sunxi/description
 SATA support for the AllWinner sunXi SoC's onboard AHCI SATA
endef

$(eval $(call KernelPackage,ata-sunxi))

define KernelPackage/sun4i-emac
  SUBMENU:=$(NETWORK_DEVICES_MENU)
  TITLE:=AllWinner EMAC Ethernet support
  DEPENDS:=@TARGET_sunxi +kmod-of-mdio +kmod-libphy
  KCONFIG:=CONFIG_SUN4I_EMAC
  FILES:=$(LINUX_DIR)/drivers/net/ethernet/allwinner/sun4i-emac.ko
  AUTOLOAD:=$(call AutoProbe,sun4i-emac)
endef

$(eval $(call KernelPackage,sun4i-emac))

define KernelPackage/sound-soc-sunxi
  TITLE:=AllWinner built-in SoC sound support
  KCONFIG:=CONFIG_SND_SUN4I_CODEC
  FILES:=$(LINUX_DIR)/sound/soc/sunxi/sun4i-codec.ko
  AUTOLOAD:=$(call AutoLoad,65,sun4i-codec)
  DEPENDS:=@TARGET_sunxi +kmod-sound-soc-core
  $(call AddDepends/sound)
endef

define KernelPackage/sound-soc-sunxi/description
  Kernel support for AllWinner built-in SoC audio
endef

$(eval $(call KernelPackage,sound-soc-sunxi))

define KernelPackage/sound-soc-sunxi-spdif
  TITLE:=Allwinner A10 SPDIF Support
  KCONFIG:=CONFIG_SND_SUN4I_SPDIF
  FILES:=$(LINUX_DIR)/sound/soc/sunxi/sun4i-spdif.ko
  AUTOLOAD:=$(call AutoLoad,65,sun4i-spdif)
  DEPENDS:=@TARGET_sunxi +kmod-sound-soc-spdif
  $(call AddDepends/sound)
endef

define KernelPackage/sound-soc-sunxi-spdif/description
  Kernel support for Allwinner A10 SPDIF Support
endef

$(eval $(call KernelPackage,sound-soc-sunxi-spdif))
