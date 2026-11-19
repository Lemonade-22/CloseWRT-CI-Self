# AI_README

给接手这个仓库的 AI / 协作者看的说明。人类向的说明看 `README.md`。

## 仓库定位

OpenWrt / ImmortalWrt 固件自动构建。**自维护机型**（上游不支持或需要改板级代码的）放 `custom/`，其它走 `Config/`。

## 三种 workflow 的分工

```
WRT-CORE.yml        通用构建核心（被 CWRT-ALL / N60-Pro-498M / WRT-TEST 调用）
WRT-CORE-SELF.yml   自维护机型的构建核心（被 TR3000 调用）
<机型>.yml           触发入口，只负责 matrix 定义 + 传参
```

调用关系固定：机型 workflow 用 `uses: ./.github/workflows/WRT-CORE*.yml`，不自己写构建步骤。

## 新增一个自维护机型

```
custom/<机型>/
  Config/<机型>-<变体>.txt    每份 .config，只差设备名等少量行
  patches/*.patch             DTS / target 补丁
  scripts/Packages.sh         第三方插件入口（默认留空框架）
  scripts/Settings.sh         主机名 / IP / WiFi / 主题落地
  README.md                   硬件事实与数值出处
```

再建一个 `<机型>.yml` 指向 `WRT-CORE-SELF.yml`。

## 硬性规则（踩过的坑）

1. **job 级 `if` 不能引用 `matrix.*`**。它矩阵展开前求值，会让整个 workflow 解析失败（GitHub 报 `Unrecognized named-value: 'matrix'`），表现为 0 秒失败、一个 job 都不起。过滤要写在 `matrix` 定义里：

```yaml
matrix:
  CONFIG: ${{ fromJSON(!inputs.FLASH && '["A","B"]' || format('["{0}"]', inputs.FLASH)) }}
```

2. **`CONFIG_PACKAGE_xxx=y` 只代表包被选中，不代表功能可用。** 例如 `kmod-mediatek_hnat=y` 还要 DTS 里 `&hnat { status = "okay"; }` 才真正启用。
   DTS 类改动必须先和主线同型号的 `.dts` 逐项 diff：分区、NMBM、MAC 读取、PHY 校准、HNAT。

3. **文档声称的属性必须能在补丁里 grep 到。** 曾出现 README 写 `mtd-mac-address = <&bdinfo 0xde00>` 而补丁里根本没有的情况。

4. **同前缀的 NAT64 只能有一个状态化转换器。** 多台旁路由各配一份会因非对称流量导致查不出原因的断连。

5. **`make defconfig` 通过 ≠ 能编译。** TEST 模式只验配置层，内核、DTB、驱动、镜像都没跑。

## 自维护机型的现实约束

- 21.02 基线（Linux 5.4）插件生态很窄：`VIKINGYFY/packages` 只有 `main`（25.12 口径），`sbwml/luci-app-diskman` 只有 `main`。加包前先查有没有 21.02 分支。
- `custom/<机型>/scripts/Packages.sh` 默认是空框架，加 `UPDATE_PACKAGE` 前先跑 `git ls-remote --heads <repo> | grep 21.02`。

## 提交前必须做的检查

- `python -c "import yaml; yaml.safe_load(open(...))"` 确认 YAML 合法
- `gh workflow run <file> --repo <repo>` 触发一次，确认不是 422 解析错误（比等 push 事件快）
- 新增机型的 Config 里设备名要与 patch 里的 DTS 文件名对应
