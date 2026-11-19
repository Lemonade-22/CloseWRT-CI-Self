#!/bin/bash
# SPDX-License-Identifier: MIT
# N60 Pro 512M：defconfig 之后校验设备、分区补丁、daede 前置。
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

# 分区补丁是否真的打上了
DTS='target/linux/mediatek/dts/mt7986a-netcore-n60-pro.dts'
if [ -f "$DTS" ]; then
  if grep -q 'reg = <0x0580000 0x1fa80000>;' "$DTS"; then
    echo '  ok   ubi 已扩到 0x1fa80000（约 506.5 MiB）'
  else
    echo '::error::ubi 分区未扩展，刷机后只能用 122.5 MiB'
    FAIL=1
  fi
fi
exit $FAIL
