#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Lemonade-22
#
# N60 Pro 512M 的额外插件入口。
#
# 机型背景：源码走 Yuzhii0718/immortalwrt-mt798x-6.6-padavanonly @ openwrt-24.10-6.6，
# 内核 6.6.162，opkg 包管理。
set -euo pipefail

UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local REPO_NAME=${PKG_REPO#*/}
	local REPO_PATH="./package/$REPO_NAME"

	echo " "
	echo "==> $PKG_NAME ($PKG_REPO @ $PKG_BRANCH)"
	if ! git clone --depth=1 --single-branch --branch "$PKG_BRANCH" \
		"https://github.com/$PKG_REPO.git" "$REPO_PATH"; then
		echo "::error::克隆 $PKG_REPO 失败"
		exit 1
	fi
}

# honk：基于 eBPF 的透明代理（内核 + Doona Web 界面 + luci-app-honk）
# 仓库根下有两个包定义：honk/ 与 luci-app-honk/，OpenWrt 会递归识别。
UPDATE_PACKAGE "honk" "kenzok8/openwrt-honk" "main"

# main 的 Makefile 默认拉 stable(6.12) 核心归档；本基线是 6.6，
# 必须覆盖成 linux66 实验通道 + aarch64 资产，否则核心与内核模块对不上。
HONK_MK_DIR="./package/openwrt-honk/honk"
if [ -d "$HONK_MK_DIR" ]; then
	echo "==> 固定 honk 到 linux66 通道（内核 6.6）"
	cat > "$HONK_MK_DIR/generated-stage.mk" <<'HONK_STAGE'
PKG_SOURCE_URL:=https://github.com/kenzok8/openwrt-honk/releases/download/linux66-2026.11.18.1/
HONK_CORE_LANE:=linux66
HONK_ASSET_AARCH64:=honk-core-1a07196395ab2a05079aaa78fc46118021da388c-linux66-aarch64.tar.gz
HONK_HASH_AARCH64:=7f51a5599945379d609c53c0269caa6c08f45ff70b87c9d9abd7bf7c9157bc6f
HONK_STAGE
	cat "$HONK_MK_DIR/generated-stage.mk"
else
	echo "::error::没找到 $HONK_MK_DIR，honk 包结构可能变了"
	exit 1
fi
