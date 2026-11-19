# TR3000（Cudy TR3000 v1）

本目录是这个机型全部自维护内容。仓库里其它文件保持与上游一致，同步上游时不会碰这里。

## 一句话现状

**hanwckf 的 21.02（Linux 5.4）上游没有 TR3000。** 所以这份适配是本仓自己维护的移植，
不是"拉下来就能编"的现成支持。官方第一次支持 TR3000 是 OpenWrt 23.05（Linux 5.15）。

证据：

| 来源 | 结果 |
| --- | --- |
| `hanwckf/immortalwrt-mt798x` openwrt-21.02 的设备表 | 10 台，无 Cudy |
| `openwrt/openwrt` openwrt-21.02 的 `mt7981b-cudy-tr3000-v1.dts` | 404 |
| `openwrt/openwrt` openwrt-23.05 同一文件 | 200 |
| hanwckf 仓库 issue #356 / #407 | 都是在问"会支持 TR3000 吗"，未关闭 |

## 三种闪存容量，分三个 Release

同一块板子有三种 NAND 容量，分区只差 ubi 那一段长度，起点都是 `0x5c0000`。
每档是独立设备名，独立 Release，独立 sysupgrade 镜像——**刷错容量会认不到分区**。

| 配置 | ubi 分区 | 对应硬件 | 数值出处 |
| --- | --- | --- | --- |
| `TR3000-128M` | `0x5c0000 + 0x4000000` | 原厂 128MB | openwrt 主线 `mt7981b-cudy-tr3000-v1.dts` |
| `TR3000-256M` | `0x5c0000 + 0xe600000` | 256MB 版 | padavanonly 6.6 的 `...-256mb.dts` |
| `TR3000-512M` | `0x5c0000 + 0x1FA40000` | 512MB 改机版 | `ubi_build` 的 `diy-cudy-tr3000-512MB.sh` |

两点说明：

- `J260121/ubi_build` **只做了 512M 一档**（一份 config + 一个 diy 脚本），128M/256M 用的不是它的数。
- 主线的 128M 只划了 64MiB 的 ubi，剩下约 56MiB 空着；256M 那份则留了约 20MiB 给 NMBM。
  两处留白不一致，这里照抄各自上游原值，没有自行调和。

## 文件

```
custom/tr3000_hanwckf/
├── Config/
│   ├── TR3000-128M.txt      完整 .config（由上游 mt7981-ax3000.config 改造）
│   ├── TR3000-256M.txt
│   └── TR3000-512M.txt
├── patches/
│   └── 0001-add-cudy-tr3000.patch   设备移植：DTS×4 + 镜像定义×3 + 网络识别
└── scripts/
    ├── Packages.sh          额外插件入口（默认空，框架留着）
    └── Settings.sh          主机名/IP/WiFi/主题
```

## 移植补丁改了什么

1. 新增 `mt7981-cudy-tr3000-v1.dtsi` —— 全部硬件定义，写法按 5.4 树的同类板
   （`mt7981-cmcc-xr30.dts`），因为 5.4 没有 `nvmem-layout` / `linux,ubi` 这些新绑定。
   硬件事实（LED/按键 GPIO、MAC 在 bdinfo 0xde00）取自上游主线。
2. 三个只覆盖 ubi 长度的 `mt7981-cudy-tr3000-v1{,-256m,-512m}.dts`。
3. `image/mt7981.mk` 追加三个 `Device/` 定义，各带自己的 `IMAGE_SIZE`。
4. `02_network` 追加 LAN/WAN 映射。

补丁由临时 git 仓机械生成，hunk 行数不会手写错。

## 加速特性怎么保住的

| 特性 | 包 |
| --- | --- |
| 闭源 WiFi 驱动（802.11k/v/r、MU-MIMO 等） | `kmod-mt_wifi`、`wifi-dats` |
| 硬件 NAT / 软加速 | `kmod-mediatek_hnat`、`luci-app-turboacc-mtk` |
| MTK 硬件 QoS | `mtkhqos_util`、`luci-app-eqos-mtk` |

`WRT-CORE-SELF.yml` 在 `make defconfig` 之后按**当前配置推出的设备符号**逐条核对，
被 kconfig 丢掉会直接让流程失败，而不是编出一份没加速的固件。

## 第一次跑之前必须知道的风险

**这个移植还没经过真机验证。** 已验证的只有：补丁能干净应用、YAML 合法、
脚本过 `bash -n`、`.config` 里只有一台目标设备。没验证的是能不能编过、能不能启动。

最可能出问题的地方，按概率排：

1. **PHY 定义**。`gmac1` 挂片上 GbE PHY（`int_gbe_phy`，reg 0 / gmii），
   `gmac0` 挂 RTL8221B（c45，reg 1，GPIO39 复位、GPIO38 中断）。
   5.4 树里写法若与 6.6 不同，表现是网口不亮而不是编不过。
2. **MAC 读取**。用的是 `mtd-mac-address = <&bdinfo 0xde00>`。
   若这棵树没带 OpenWrt 的 mtd-mac 补丁，MAC 会变成随机值——能上网，但每次重启都变。
3. **容量选错**。刷入与硬件不符的那档，表现是启动后找不到 rootfs。

建议顺序：先 `TEST=true` 只跑配置 → 再放开整编 → 最后才刷机。
刷之前先备份原厂固件与分区表。

## 只编一档

`workflow_dispatch` 的 `FLASH` 填 `128M` / `256M` / `512M` 就只编那一档，留空三档全编。

## 想换到原生支持的 6.6 线

`TR3000_hanwckf.yml` 的 matrix 里有两行，注释掉 hanwckf 那行、放开 padavanonly 那行即可。
但 6.6 线的设备名（`mediatek_filogic`）与 `.config` 内容都不同，需要另建一份
`Config` 文件，不能直接复用现在的三份。
