#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
echo $TAG
echo $TAG2
echo $KERNEL_NAME
KERNEL=${KERNEL_NAME#k} && echo "Kernel：$KERNEL"
VERSION=${TAG#v} && echo "op_version：$VERSION"
VERSION2=${TAG2#v} && echo "imm_version：$VERSION2"
cat $GITHUB_OUTPUT
if [ "$(grep -c "AXT-1800" $GITHUB_OUTPUT)" -eq '1' ] ;then
  # Check for kernel-6.12 file
  KERNEL_FILE="./target/linux/generic/kernel-6.12"

  # File path
  if [ ! -f "$KERNEL_FILE" ]; then
    echo "Error: File not found $KERNEL_FILE"
    exit 1
  fi

  # Get major version
  MAJOR_VERSION=$(grep -oP 'LINUX_VERSION-\K[0-9.]+' "$KERNEL_FILE" | head -1)

  # Get minor version
  MINOR_VERSION=$(grep -oP 'LINUX_VERSION-[0-9.]+ = \K.[0-9]+' "$KERNEL_FILE" | head -1)

  # Combine versions
  KERNEL_VERSION="${MAJOR_VERSION}${MINOR_VERSION}"

  # Validate version format
  if [[ ! "$KERNEL_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid kernel version format"
    exit 1
  fi

  # Print kernel version
  echo "Kernel Version: $KERNEL_VERSION"
  echo "Using $KERNEL_VERSION for patches"

  sed -i 's/192.168.1.1/192.168.8.1/g' package/base-files/files/bin/config_generate
  
  rm -rf feeds/packages/lang/golang && echo "Removing old golang"
  git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang
  cat feeds/packages/lang/golang/golang/Makefile
  wget -qO- "https://downloads.immortalwrt.org/snapshots/targets/qualcommax/ipq60xx/kmods/" | grep -oP "$KERNEL_VERSION-1-\K[0-9a-f]+" | head -n 1 > vermagic && echo "Vermagic:" && cat vermagic
  wget https://raw.githubusercontent.com/m0eak/openwrt_patch/refs/heads/main/gl-axt1800/9999-gl-axt1800-dts-change-cooling-level.patch && echo "Patch download successful" || echo "Patch download failed"
  mv 9999-gl-axt1800-dts-change-cooling-level.patch ./target/linux/qualcommax/patches-6.12/9999-gl-axt1800-dts-change-cooling-level.patch && echo "Patch move successful" || echo "Patch move failed"
  rm package/kernel/mac80211/patches/nss/ath11k/999-902-ath11k-fix-WDS-by-disabling-nwds.patch && echo "patch1 removed" || echo "patch1 removal failed (already removed?)"
  rm package/kernel/mac80211/patches/nss/subsys/999-775-wifi-mac80211-Changes-for-WDS-MLD.patch && echo "patch2 removed" || echo "patch2 removal failed (already removed?)"
  # rm package/kernel/mac80211/patches/nss/subsys/999-922-mac80211-fix-null-chanctx-warning-for-NSS-dynamic-VLAN.patch && echo "patch2 removed" || echo "patch2 removal failed (already removed?)"
  if [ ! -s ./vermagic ]; then
    echo "none vermagic"
  else
    sed -i '/grep '\''=\[ym\]'\'' $(LINUX_DIR)\/\.config\.set | LC_ALL=C sort | $(MKHASH) md5 > $(LINUX_DIR)\/\.vermagic/s/^/# /' ./include/kernel-defaults.mk
    sed -i '/$(LINUX_DIR)\/\.vermagic/a \\tcp $(TOPDIR)/vermagic $(LINUX_DIR)/.vermagic' ./include/kernel-defaults.mk
  fi
fi