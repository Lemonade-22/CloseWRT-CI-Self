#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 Lemonade-22
#
# 把 CWRT 那套习惯（主机名、地址、WiFi 名/密码、主题）落到 21.02 树上。
# 每一步都带存在性判断：21.02 的路径和 25.x 不一样，找不到就跳过并说一声，
# 不能让一个 sed 把整轮编译带崩。
set -euo pipefail

say() { echo " "; echo "==> $*"; }

# ---- 默认 IP / 主机名 ----
CFG="./package/base-files/files/bin/config_generate"
if [ -f "$CFG" ]; then
	say "改默认 IP 与主机名"
	sed -i "s/192\.168\.[0-9]*\.[0-9]*/${WRT_IP}/g" "$CFG"
	sed -i "s/hostname='.*'/hostname='${WRT_NAME}'/g" "$CFG"
else
	echo "跳过：没找到 $CFG"
fi

# ---- WiFi 名称与密码（hanwckf 闭源栈走 mtwifi.sh）----
WIFI_FILE="./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
if [ -f "$WIFI_FILE" ]; then
	say "改 WiFi 名称与加密"
	sed -i "s/ImmortalWrt/${WRT_SSID}/g" "$WIFI_FILE"
	sed -i "s/encryption=.*/encryption='psk2+ccmp'/g" "$WIFI_FILE"
	if ! grep -q "set wireless.default_\${dev}.key=" "$WIFI_FILE"; then
		sed -i "/set wireless.default_\${dev}.encryption='psk2+ccmp'/a \\t\\t\\t\\tset wireless.default_\${dev}.key='${WRT_WORD}'" "$WIFI_FILE"
	fi
else
	echo "跳过：没找到 $WIFI_FILE（这个树里 wifi 配置脚本不在这个位置）"
fi

# ---- luci 语言与主题 ----
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config

# 主题只在 feeds 里真有这个包时才写进 .config，否则 defconfig 会静默丢掉
if ls ./feeds/luci/themes/luci-theme-"$WRT_THEME" >/dev/null 2>&1; then
	say "启用主题 $WRT_THEME"
	echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
else
	echo "跳过主题 $WRT_THEME：feeds 里没有，保持默认 bootstrap"
fi

# ---- 手动追加 ----
if [ -n "${WRT_PACKAGE:-}" ]; then
	say "追加手动指定的 .config 片段"
	printf '%s\n' "${WRT_PACKAGE}" >> ./.config
fi

if [ -f "$GITHUB_WORKSPACE/custom/tr3000/Config/PRIVATE.txt" ]; then
	say "合并 PRIVATE.txt"
	cat "$GITHUB_WORKSPACE/custom/tr3000/Config/PRIVATE.txt" >> ./.config
fi
