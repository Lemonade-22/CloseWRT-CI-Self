# Netcore N60 Pro 512M NAND（MT7986A / filogic）

## 硬件

| 项 | 值 |
|---|---|
| SoC | MediaTek MT7986A（filogic） |
| 闪存 | 512 MB NAND |
| 设备名 | `mediatek_filogic_DEVICE_netcore_n60-pro` |
| DTS | `target/linux/mediatek/dts/mt7986a-netcore-n60-pro.dts` |

## 源码基线

```
Yuzhii0718/immortalwrt-mt798x-6.6-padavanonly @ openwrt-24.10-6.6
```

这是上游 CloseWRT-CI 的 MT7986 口径。选它的原因是**它带 MTK 闭源 WIFI**：

```
package/mtk/drivers/mt_wifi/          闭源驱动
package/mtk/applications/mtwifi-cfg/  配置工具
```

对照：`VIKINGYFY/immortalwrt@owrt`（OWRT 用的那条）这两条路径都是 404，没有闭源驱动；
而 `Yuzhii0718@openwrt-24.10-6.6` 里 `package/kernel/mt76` 也不存在，
**所以这套源码是纯闭源，没有开源 mt76 可选**——上游那两档 WIFI-YES/NO 在这里没有对应开关。

## 512M 分区必须扩

上游设备树把 ubi 限在 `0x7280000`（120 MB），可这颗芯片有 512 MB NAND。
`patches/n60pro-512m-ubi-5065m.patch` 把它改成 `0x1fa80000`（约 506.5 MiB），
不打这个补丁，sysupgrade 只能写进 120 MB。

补丁编号：

```
- reg = <0x0580000 0x7280000>;
+ reg = <0x0580000 0x1fa80000>;
```

## daede 支持（软件层同 OWRT）

固件**不预装** daed / dae / luci-app-daede，只准备内核 eBPF 前提，用户自行安装时开箱即用：

```
Config/DAEDE.txt   25 行内核选项（BTF、cgroup BPF、kprobes、XDP sockets…）
```

由 `scripts/Settings.sh` 在 `Config/GENERAL.txt` 之后追加——顺序很关键，
写在前面的会被通用配置覆盖。依据：https://github.com/kenzok8/openwrt-daede

## 闭源 WIFI

来自上游 `Config/GENERAL.txt`（SELF 自动叠加），不在本目录重复：

```
CONFIG_PACKAGE_kmod-mt_wifi=y
CONFIG_PACKAGE_mtwifi-cfg=y
CONFIG_PACKAGE_luci-app-mtwifi-cfg=y
CONFIG_MTK_MT_WIFI=m
CONFIG_MTK_WIFI_ADIE_TYPE="mt7976"
CONFIG_MTK_WIFI_DRIVER=y
```

## 构建产物

沿用 CWRT 的 bin 结构，由 SELF 的 Package Firmware 处理：
squashfs 根（`Settings.sh` 里强制 `CONFIG_TARGET_ROOTFS_SQUASHFS=y`）、
initramfs-kernel、factory 与 sysupgrade 镜像，文件名带 `-` 源码/分支/时间戳后缀。

## 校验

`scripts/verify.sh` 在 defconfig 之后检查：设备符号、闭源 wifi、daede 前置、squashfs 根，
并回读 DTS 确认 ubi 真的扩到了 `0x1fa80000`——补丁打了但没匹配上会当场报错。

## 已知限制

- 未上机验证：分区识别、闭源 wifi 双频、2.5G 口协商、daed 实际转发。
- 512M 分区扩展是按 NAND 标注容量推算的，不同批次硬件可能不同，刷机前先备份。
- 与 TR3000（hanwckf 21.02）是两条完全不同的基线，别互相套用 Config。
