#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Lemonade-22
#
# 机型判别。构建核心（WRT-CORE-SELF.yml）保持通用，机型差异全部由这里分派：
#   Device.sh resolve   <CONFIG>   输出 DEVICE / DEVICE_DIR 供 eval
#   Device.sh configure <CONFIG>   机型特定的预处理（当前无）
#   Device.sh verify    <CONFIG>   校验机型目录与 Config 是否齐全
#
# 新增自维护机型时只改这个文件的 case 一支 + 在 custom/ 下建目录。
set -euo pipefail

ACTION="${1:-resolve}"
CONFIG="${2:-${WRT_CONFIG:-}}"

DEVICE=""
case "$CONFIG" in
  TR3000-*_hanwckf) DEVICE="tr3000_hanwckf" ;;
  N60-Pro-512M) DEVICE="n60-pro-512m" ;;
esac

if [ -z "$DEVICE" ]; then
  case "$ACTION" in
    resolve) echo "DEVICE="; echo "DEVICE_DIR=" ;;
  esac
  exit 0
fi

DEVICE_DIR="custom/$DEVICE"

case "$ACTION" in
  resolve)
    echo "DEVICE=$DEVICE"
    echo "DEVICE_DIR=$DEVICE_DIR"
    ;;
  configure)
    echo "==> 机型 $DEVICE（$CONFIG）"
    ;;
  verify)
    [ -f "$DEVICE_DIR/Config/$CONFIG.txt" ] || {
      echo "::error::缺少 $DEVICE_DIR/Config/$CONFIG.txt"; exit 1; }
    echo "机型配置齐备：$DEVICE_DIR/Config/$CONFIG.txt"
    ;;
  *)
    echo "::error::未知动作 $ACTION"; exit 1 ;;
esac