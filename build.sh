#!/bin/bash

#
# setup environment
# edit CC to match your toolchain path if you're not working inside the CM/AOSP built tree
#
CC="../../../prebuilts/gcc/linux-x86/arm/arm-eabi-4.6/bin/arm-eabi-"
DATE=$(date +%m%d)
J=$(cat /proc/cpuinfo | grep "^processor" | wc -l)
HOME=$(pwd)
WORK=$(dirname $0)

DIE() { LOG "FAILED : $*"; exit 1; }
LOG() { printf "\n$@\n\n"; }
TRY() { "$@" || DIE "$@"; }

MKBOOTIMG() {
	LOG "Creating boot.img..."
	TRY ./mkbootimg --kernel arch/arm/boot/zImage \
			--ramdisk ramdisk/ramdisk.gz \
			--cmdline "console=null androidboot.hardware=qcom user_debug=31" \
			--base 0x80200000 \
			--pagesize 2048 \
			--ramdisk_offset 0x01300000 \
			-o boot.img
	LOG "Your boot.img has been successfully compiled"
	ls -lh boot.img
}

#
# no CC?!? GTFO!
#
if [ ! -e "$WORK/$CC"gcc ]; then
	LOG "You must have a valid cross compiler installed !"
	LOG "Would you like to download and automatically configure your toolchain ?"
	LOG "Type Y or N"
	read answer

	if [ $answer == 'Y' ]; then
		LOG "This may take a while..."
		TRY git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-eabi-4.6 $WORK/../arm-eabi-4.6
		TRY sed -i "s/..\/..\/..\/prebuilts\/gcc\/linux-x86\/arm/../g" $0
		CC="$WORK/../arm-eabi-4.6/bin/arm-eabi-"
	else
		LOG "WTF is \"$answer\" supposed to mean anyways ?"
		printf "YOU "
		DIE "AT LIFE"
	fi
fi

#
# cleanup
#
TRY bash $WORK/clean

#
# setup android initramfs
#
TRY cd $WORK/ramdisk/root
TRY find . -print | cpio -o -H newc | gzip -9n > ../ramdisk.gz

#
# setup config
#
TRY cd ../..
TRY make ARCH=arm CROSS_COMPILE=$CC custom_expressatt_defconfig

#
# compile
#
TRY make -j $J ARCH=arm CROSS_COMPILE=$CC zImage
TRY make -j $J ARCH=arm CROSS_COMPILE=$CC modules

#
# package
#
if [ ! -e arch/arm/boot/zImage ]; then
	DIE "Sumthin done fucked up. I suggest you fix it."
else
	MKBOOTIMG
fi

#
# Fin
#
LOG "Done !"
