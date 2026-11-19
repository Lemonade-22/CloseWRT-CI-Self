#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Lemonade-22
#
# TR3000（hanwckf 21.02）机型校验：make defconfig 之后跑。
# 这些包是这次移植的核心卖点，被 kconfig 静默丢掉要当场报错。
set -euo pipefail

FAIL=0
for SYM in \
  "CONFIG_PACKAGE_kmod-mt_wifi=y" \
  "CONFIG_PACKAGE_kmod-mediatek_hnat=y" \
  "CONFIG_PACKAGE_luci-app-turboacc-mtk=y"; do
  if grep -qx "$SYM" .config; then
    echo "  ok   $SYM"
  else
    echo "::error::config lost: $SYM"
    FAIL=1
  fi
done

# HNAT 光有包不够，DTS 里节点必须真的启用（这是上一轮踩过的坑）
if [ -f target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-cudy-tr3000-v1.dtsi ]; then
  if grep -q '&hnat' target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-cudy-tr3000-v1.dtsi; then
    echo "  ok   DTS 已启用 &hnat"
  else
    echo "::error::补丁里没有 &hnat 覆盖，硬件 NAT 不会工作"
    FAIL=1
  fi
fi

exit $FAIL