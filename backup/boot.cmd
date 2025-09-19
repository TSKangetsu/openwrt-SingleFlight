# U-Boot boot script for FriendlyARM NanoPi NEO Air
# OpenWrt initramfs kernel boot via sunxi-fel (with separate DTB)
# This version is for initramfs-kernel.bin and a separate DTB

# Set console and boot arguments
setenv console ttyS0,115200
setenv bootargs console=${console} earlyprintk root=/dev/ram0 rw init=/sbin/init

# Memory addresses
setenv kernel_addr 0x45000000
setenv dtb_addr 0x48000000

# Boot information
echo "================================================"
echo "  NanoPi NEO Air OpenWrt Boot (Separate DTB)"
echo "================================================"
echo "Kernel address: ${kernel_addr}"
echo "DTB address:    ${dtb_addr}"
echo "Boot args:      ${bootargs}"
echo ""

# Boot initramfs kernel with embedded ramdisk and separate DTB
echo "Booting OpenWrt initramfs kernel (separate DTB)..."
bootm ${kernel_addr} - ${dtb_addr}