#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Lemonade-22
#
# N60 Pro 512M：在通用配置（Config/GENERAL.txt）叠加之后追加机型专属项。
# 这里的东西优先级最高——SELF 的流程是 cp Config -> cat GENERAL -> 跑本脚本 -> make defconfig。
set -euo pipefail

CI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DEVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# daede 的内核前提
if [ -f "$DEVICE_DIR/Config/DAEDE.txt" ]; then
  echo "==> 追加 daede 内核前提"
  cat "$DEVICE_DIR/Config/DAEDE.txt" >> ./.config
fi

# 512M 版：确保 squashfs 根是打包对象（上游 filogic 默认出 sysupgrade.itb）
sed -i '/^CONFIG_TARGET_ROOTFS_SQUASHFS=/d; /^# CONFIG_TARGET_ROOTFS_SQUASHFS is not set$/d' .config
echo 'CONFIG_TARGET_ROOTFS_SQUASHFS=y' >> .config
