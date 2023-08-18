define Device/singleflight_licheepi-nano
  DEVICE_VENDOR := singleflight
  DEVICE_MODEL := singleflight Licheepi Nano
  SOC := suniv-f1c100s
  RAW_KERNEL := Y
endef
TARGET_DEVICES += singleflight_licheepi-nano

define Device/singleflight_flash_licheepi-nano
  DEVICE_VENDOR := singleflight
  DEVICE_MODEL := singleflight Licheepi Nano for SPI-FLASH
  SOC := suniv-f1c100s
  RAW_KERNEL := Y
  SPI_FLASH := Y
endef
TARGET_DEVICES += singleflight_flash_licheepi-nano
