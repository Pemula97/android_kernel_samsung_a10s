#!/bin/bash

# ==============================
# Setup environment
# ==============================
export PATH=$(pwd)/toolchain/bin:$PATH
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export KBUILD_BUILD_USER=Windows
export KBUILD_BUILD_HOST=Ubuntu-Wsl
export ARCH=arm64
export SUBARCH=arm64

# KernelSU
echo "KernelSU..."
git submodule update --init "$(pwd)/KernelSU"

export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y
JOBS=$(nproc --all)

echo "Check PATH..."
which clang

# ==============================
# Build kernel
# ==============================
make -C $(pwd) O=$(pwd)/out CC=clang KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y a10s_defconfig
make -C $(pwd) O=$(pwd)/out CC=clang KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y -j$JOBS 2>&1 | tee build.log

# Stop kalau build gagal
if [ $? -ne 0 ]; then
    echo "❌ Build kernel gagal, repack dibatalkan!"
    exit 1
fi

# ==============================
# Variables for mkbootimg
# ==============================
DIR_KERNEL=$(pwd)/out/arch/arm64/boot/Image.gz
DIR_DTB=$(pwd)/out/arch/arm64/boot/dts/mediatek/mt6765.dtb
DIR_TOOLS=$(pwd)/tools/make/bin/mkbootimg
OUTPUT=$(pwd)/new-boot.img

# ==============================
# Repack boot.img
# ==============================
echo " "
echo "I: Building kernel image..."
echo "    Header/Page size: 1660/2048"
echo "      Board and base: SRPSD12A008/0x40078000"
echo " "
echo "     Android Version: 10.0.0"
echo "Security patch level: 2021-04"

# Cek file kernel
if [ ! -f "$DIR_KERNEL" ]; then
    echo "❌ Build gagal: kernel not found ($DIR_KERNEL)"
    exit 1
fi

# Cek file dtb
if [ ! -f "$DIR_DTB" ]; then
    echo "❌ Build gagal: dtb not found ($DIR_DTB)"
    exit 1
fi

# Jalankan mkbootimg
$DIR_TOOLS \
  --kernel $DIR_KERNEL \
  --dtb $DIR_DTB \
  --cmdline "androidboot.selinux=permissive bootopt=64S3,32N2,64N2" \
  --base 0x40078000 \
  --board SRPSD12A008 \
  --pagesize 2048 \
  --kernel_offset 0x00008000 \
  --ramdisk_offset 0x11a88000 \
  --second_offset 0x00e88000 \
  --tags_offset 0x07808000 \
  --os_version 10.0.0 \
  --os_patch_level 2021-04 \
  --header_version 2 \
  -o $OUTPUT

# ==============================
# Result check
# ==============================
if [ $? -eq 0 ] && [ -f "$OUTPUT" ]; then
    echo "✅ Build kernel + boot.img selesai!"
    ls -lh "$OUTPUT"
else
    echo "❌ Build gagal saat proses mkbootimg!"
    exit 1
fi
