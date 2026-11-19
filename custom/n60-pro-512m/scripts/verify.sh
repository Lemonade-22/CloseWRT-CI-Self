#!/bin/bash
# SPDX-License-Identifier: MIT
# N60 Pro 512M：defconfig 之后校验设备、NMBM/分区补丁、daede 前置。
set -euo pipefail
FAIL=0
check() {
  if grep -qE "$1" .config; then echo "  ok   $2"; else echo "::error::$2 缺失"; FAIL=1; fi
}
check '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_netcore_n60-pro=y$' '设备 netcore_n60-pro 已选中'
check '^CONFIG_PACKAGE_kmod-mt_wifi=y$' '闭源 wifi 驱动'
check '^CONFIG_KERNEL_BPF_EVENTS=y$' 'daede 前置：BPF events'
check '^CONFIG_KERNEL_KPROBES=y$' 'daede 前置：kprobes'
check '^CONFIG_TARGET_ROOTFS_SQUASHFS=y$' 'squashfs 根'

# 补丁是否真的打上了：NMBM 必须 256（否则 NMBM 找不到签名，刷完不开机）
DTS='target/linux/mediatek/dts/mt7986a-netcore-n60-pro.dts'
if [ -f "$DTS" ]; then
  if grep -q 'mediatek,bmt-max-reserved-blocks = <256>;' "$DTS"; then
    echo '  ok   NMBM reserved-blocks = 256'
  else
    echo '::error::NMBM reserved-blocks 不是 256，刷机可能不开机（见 OpenWrt PR #24001）'
    FAIL=1
  fi
  if grep -q 'reg = <0x0580000 0x1DA80000>;' "$DTS"; then
    echo '  ok   ubi 扩到 0x1DA80000（约 474 MiB，尾部留 32 MiB 给 NMBM）'
  else
    echo '::error::ubi 长度不对，应为 0x1DA80000（512MiB - 5.5MiB 起点 - 32MiB NMBM）'
    FAIL=1
  fi
fi
exit $FAIL
