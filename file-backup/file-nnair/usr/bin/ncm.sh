#! /bin/ash

# rmmod g_webcam
# rmmod usb_f_uvc
# # modprobe g_ncm
# modprobe g_ether

modprobe libcomposite
mount -t configfs none /sys/kernel/config
mkdir -p /sys/kernel/config/usb_gadget/g1
cd /sys/kernel/config/usb_gadget/g1

###############################
# Populate Device-Level Stuff #
###############################

#Setting device class/subclass/protocol to these values
# alerts the OS that this is a composite device with
# IADs in it's firmware.
# ref: https://docs.microsoft.com/en-us/windows-hardware/drivers/usbcon/usb-interface-association-descriptor
echo "0xEF" > bDeviceClass
echo "0x02" > bDeviceSubClass
echo "0x01" > bDeviceProtocol
echo "0x1d6b" > idVendor
echo "0x0104" > idProduct

mkdir strings/0x409
echo "1234567" > strings/0x409/serialnumber
echo "Some Manufacturer" > strings/0x409/manufacturer
echo "Some Product" > strings/0x409/product

#enable use of os_desc's (important for RNDIS & NCM enablement on Windows):
echo 1       > os_desc/use
echo 0xbc    > os_desc/b_vendor_code
echo MSFT100 > os_desc/qw_sign

#################################
# Populate Individual Functions #
#################################

#The order functions are populated here will be reflected in the
# order of descriptors written.

#########
# RNDIS #
#########
#Note! If RNDIS is enabled, it *has* to be the first function! Otherwise, Windows 10 will report error 10 (failed to start device).
# (It's unclear why this is the case..)
# https://docs.microsoft.com/en-us/answers/questions/474108/does-rndis-need-to-be-listed-as-the-first-function.html
# https://stackoverflow.com/questions/68365739/windows-rndis-compatible-device-does-rndis-need-to-be-listed-as-the-first-funct
if false
then
	mkdir functions/rndis.usb0
	mkdir -p functions/rndis.usb0/os_desc/interface.rndis

	#Set compatible / sub-compatible id's so that Windows can match this
    # function to RNDIS6 driver more easily.
	echo RNDIS   > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
	echo 5162001 > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

	mkdir -p configs/c.1
	mkdir -p configs/c.1/strings/0x409
	echo "conf1" > configs/c.1/strings/0x409/configuration
	ln -s functions/rndis.usb0 configs/c.1
	if [ ! -L os_desc/c.1 ]
	then
	 	ln -s configs/c.1 os_desc
	fi
fi

#########
# NCM   #
#########
#Usually I test with *either* RNDIS or NCM enabled, but not both, hence the if(0) here..
if true
then
	mkdir functions/ncm.usb0
	mkdir -p functions/ncm.usb0/os_desc/interface.ncm
    #Set compatible id so that Windows 10 can match this function to
    # NCM driver more easily.
	echo WINNCM   > functions/ncm.usb0/os_desc/interface.ncm/compatible_id

	mkdir -p configs/c.1
	mkdir -p configs/c.1/strings/0x409
	echo "conf1" > configs/c.1/strings/0x409/configuration
	ln -s functions/ncm.usb0 configs/c.1
	if [ ! -L os_desc/c.1 ]
	then
		 ln -s configs/c.1 os_desc
	fi
fi

#########
# ACM   #
#########
if false
then
	mkdir -p functions/acm.GS0

	mkdir -p configs/c.1
	mkdir -p configs/c.1/strings/0x409
	ln -fs functions/acm.GS0 configs/c.1
	if [ ! -L os_desc/c.1 ]
	then
		 ln -s configs/c.1 os_desc
	fi
fi

#bind..
# Chances are, you need to replace this line with the platform-specific UDC.
# Use 'ls /sys/class/udc' to see available UDCs
echo "using musb-hdrc.1.auto for UDC.. you probably need to replace this.."
echo musb-hdrc.1.auto > UDC