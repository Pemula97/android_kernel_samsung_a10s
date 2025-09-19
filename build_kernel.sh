#!/bin/bash

export PATH=$(pwd)/toolchain/bin:$PATH
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export KBUILD_BUILD_USER=Windows
export KBUILD_BUILD_HOST=Ubuntu-Wsl
export ARCH=arm64
export SUBARCH=arm64

# KernelSu
echo "KernelSU..."
git submodule update --init "$(pwd)/KernelSU"

export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y
JOBS=$(nproc --all)

echo "chek PATH..."
which clang

make -C $(pwd) O=$(pwd)/out CC=clang KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y a10s_defconfig
make -C $(pwd) O=$(pwd)/out CC=clang KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y -j$JOBS 2>&1 | tee build.log

cp out/arch/arm64/boot/Image $(pwd)/arch/arm64/boot/Image
