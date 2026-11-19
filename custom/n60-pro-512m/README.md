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

## 分区必须与 U-Boot layout 对齐（改错会砖）

这块板子刷了 **WildEdition U-Boot**（v2.13.0），Web 界面 `10.10.10.1` 可以在多套分区布局间切换。
**固件 DTS 的 ubi 长度必须与 U-Boot 选中的那个 layout 一致**，否则两边对 flash 的理解不同。

实测 U-Boot 提供的布局（`/api/mtd_layouts`，闪存 Winbond W25N04KV / 512 MB / 4096 块 × 128 KB）：

| layout | ubi | 尾部剩余 |
|---|---|---|
| `default` / `...-500MB-data-1m` | `0x580000+0x1F400000`（500 MiB） | 5.5 MiB + data 1 MiB |
| **`spi-nand-512MB-ubi-490MB`** | **`0x580000+0x1EA00000`（490 MiB）** | **16.5 MiB** |
| `spi-nand-512MB-ubi-460MB` | `0x580000+0x1CC00000`（460 MiB） | 46.5 MiB |
| `spi-nand-512MB-MAX-506.5MB` | `0x580000+0x1FA80000`（506.5 MiB） | 0 |
| `spi-nand-512MB-ubi-400MB-data-100m` | `0x580000+0x19000000`（400 MiB） | + data 100 MiB |
| `spi-nand-512MB-ubi-114.5MB-data-385m` | `0x580000+0x07280000`（114.5 MiB） | + data 385 MiB |

### 本仓采用：U-Boot 选 `ubi-490MB`，DTS 写 `0x1EA00000`

```
U-Boot   spi-nand-512MB-ubi-490MB
           ubi@0x580000 + 0x1EA00000

DTS      reg = <0x0580000 0x1EA00000>;
           bmt-max-reserved-blocks = <64>;   ← 保持原厂值
```

容量核对：

```
ubi 结束   0x580000 + 0x1EA00000 = 0x1EF80000
芯片       0x20000000
尾部剩余   0x1080000 = 16.5 MiB
NMBM 需求  64 块 × 128 KiB = 8 MiB   → 够用
```

### 两个踩过的坑

**1. `bmt-max-reserved-blocks` 不要改成 256。**
OpenWrt PR #24001 把 Keenetic/Netcraze 的该值从 64 改成 256，那是因为**那些板子的原厂值就是 256**。
Netcore（磊科）N60 Pro 不是同一家，U-Boot 各 layout 的尾部预留量与 64 块 × 128 KiB 对得上。
盲目套用会让 NMBM 找不到签名，刷完不开机。

**2. 不要写 `size = <0x0>`。**
那是 Keenetic KN-3811 的写法，但它的树有 `compatible = "linux,ubi"` 新绑定，尾部边界由内核算。
本仓用的 6.6 padavanonly 树没有该绑定（全树 `linux,ubi` 零命中），
写 `0x0` 会把 NMBM 的 BMT 表一起吃掉。

**3. 不要选 `MAX-506.5MB`**（除非改用 `linux,ubi` 绑定）。
它把 ubi 顶到芯片末尾、尾部预留 0，BMT 无处可放。

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
