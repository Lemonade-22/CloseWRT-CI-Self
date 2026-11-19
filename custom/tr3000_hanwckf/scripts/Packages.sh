#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Lemonade-22
#
# 额外插件入口。21.02 的 feeds 全部锁在 openwrt-21.02 分支，
# 上游 CloseWRT 里那些面向 25.12 的主题/插件直接拉过来基本都编不过，
# 所以这里默认不放任何 clone，只留一个能用的框架。
#
# 要用就照下面的签名加一行，并在加之前确认该仓库确实有 openwrt-21.02 分支：
#   git ls-remote --heads https://github.com/<owner>/<repo>.git | grep 21.02
set -euo pipefail

UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local REPO_NAME=${PKG_REPO#*/}
	local REPO_PATH="./package/$REPO_NAME"

	echo " "
	echo "==> $PKG_NAME ($PKG_REPO @ $PKG_BRANCH)"

	# 删掉 feeds 里同名/近名的旧包，避免 coremark 之类的符号冲突
	local FOUND
	FOUND=$(find ./feeds/luci/ ./feeds/packages/ -maxdepth 3 -type d -iname "*$PKG_NAME*" 2>/dev/null || true)
	if [ -n "$FOUND" ]; then
		while read -r DIR; do
			[ -n "$DIR" ] && rm -rf "$DIR" && echo "  删除 $DIR"
		done <<< "$FOUND"
	fi

	if ! git clone --depth=1 --single-branch --branch "$PKG_BRANCH" \
		"https://github.com/$PKG_REPO.git" "$REPO_PATH"; then
		echo "::error::克隆 $PKG_REPO 失败，检查仓库与分支是否存在"
		exit 1
	fi
}

# ---- 示例（放开前先确认分支存在）----
# UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-21.02"
# UPDATE_PACKAGE "diskman" "sbwml/luci-app-diskman" "master"

# 私有扩展
if [ -f "$GITHUB_WORKSPACE/custom/tr3000_hanwckf/scripts/PRIVATE.sh" ]; then
	# shellcheck disable=SC1091
	source "$GITHUB_WORKSPACE/custom/tr3000_hanwckf/scripts/PRIVATE.sh"
fi
