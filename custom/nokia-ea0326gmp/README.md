# Nokia EA0326GMP（占位）

本目录预留给 **Nokia EA0326GMP** 的适配内容，**目前为空**。

> 曾误记为 "Nokia 3026"，完整型号是 **EA0326GMP**（EA-0326-GMP）。

## 硬件规格

| 项 | 值 |
|---|---|
| SoC | MediaTek MT7981B（2× Cortex-A53） |
| Flash | 128 MB SPI-NAND |
| RAM | 256 MB |
| 交换芯片 | MediaTek MT7531AE（4× 10/100/1000 Mbps） |
| WiFi | MediaTek MT7976C |
| OpenWrt 设备名 | `nokia_ea0326gmp` |
| 上游支持 | openwrt/openwrt PR #14993 |

**与 Cudy TR3000 同为 MT7981B 平台**，所以 `custom/tr3000_hanwckf/` 里的 DTS 写法、Config 结构、Settings.sh 的路径假设都可以参考。

## 移植时按 tr3000 的结构填

```
Config/    各容量 / 版本的 .config
patches/   DTS 与 target 补丁
scripts/   Packages.sh（第三方插件入口）、Settings.sh（主机名/IP/WiFi 落地）
```

注意事项：

- 仓库其它文件保持与上游一致，机型相关内容只放这里，同步上游时不冲突。
- 设备名从 Config 的 `CONFIG_TARGET_DEVICE_...` 反推，不需要在 workflow 里再写一遍。
- 新建 workflow 时，job 级 `if` 不能引用 `matrix.*`（矩阵展开前求值会解析失败），过滤要写在 `matrix` 定义里，用 `fromJSON(...)` 生成。
- EA0326GMP 原厂固件里的配置工具是动态链接的（见 PR 里提到的 `config-utils`），改机前要先备份。
