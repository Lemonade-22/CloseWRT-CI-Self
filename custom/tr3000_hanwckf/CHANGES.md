# TR3000 板级修复摘要

适用于 hanwckf 21.02 的 TR3000 v1 128M、256M、512M 三种配置。

- **升级**：三个设备名均接入 sysupgrade tar 格式检查和 NAND 升级流程。
- **以太网**：LAN 从 `bdinfo + 0xde00` 读取原厂 MAC，WAN 使用该地址加一。片上千兆 PHY 接入 SoC 的校准数据。
- **硬件 NAT**：在共用设备树中启用 HNAT，并按现有端口定义设置 WAN 为 `eth0`、LAN 为 `eth1`。

已在上游提交 `740103d6` 对应文件上通过 `git apply --check` 并实际应用补丁。Windows 环境未能启动 Bash 做语法检查。此次修改尚未整编或上机；刷写前仍需核实各容量的 NMBM 布局与闭源 Wi-Fi EEPROM 偏移，随后验证双网口、无线、HNAT 转发与系统升级。
