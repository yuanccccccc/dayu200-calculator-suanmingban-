# 计算器（隐藏算命彩蛋）— OpenHarmony 6.1.1-LTS / API 23

DAYU200（RK3568）上的 ArkTS 应用：表面是一个普通计算器，输入生日数字后按 `=` 才会进入算命流程，
界面上没有任何入口。

当前分支 `openharmony-6.0` 由 API 9 版本适配而来，运行在 **OpenHarmony 6.1.1-LTS（API 23，
SDK 构建版本 6.1.0.47-Release）** 上。

## 1. 环境要求

| 组件 | 版本 |
| --- | --- |
| Node.js | ≥ 24.14.1（hvigor 6.26.9 的硬性要求） |
| JDK | 8 或 17（`PackageHap` 会调用 `java`，未在 PATH 中会报 `spawn java ENOENT`） |
| OpenHarmony SDK | 6.1.1-LTS 公共 SDK，API 23 |

SDK 需解压到 `<SDK根目录>\23\`，每个组件目录下有 `oh-uni-package.json`：

```
Sdk\23\ets\oh-uni-package.json
Sdk\23\js\...
Sdk\23\native\...
Sdk\23\toolchains\...
Sdk\23\previewer\...
```

在项目根目录的 `local.properties` 中指定 SDK 根目录（该文件不入库）：

```properties
sdk.dir=C:\\Users\\<你>\\AppData\\Local\\OpenHarmony\\Sdk
```

也可以改用环境变量 `DEVECO_SDK_HOME`。

## 2. 构建

```bash
npm install          # 安装 package.json 中固定版本的 hvigor 6.26.9（约 2 个包）
./hvigorw assembleHap --mode module -p product=default --no-daemon
```

Windows cmd/PowerShell 用 `hvigorw.bat`，参数相同。

产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`

> 旧版 `hvigor/hvigor-wrapper.js`（hvigor 2.0.0）不认识本项目的 `modelVersion: 6.0.0`，
> 已移除；`hvigorw` / `hvigorw.bat` 改为直接调用 `node_modules` 里的 hvigor。
> 如果不装 node_modules，也可以用 DevEco Studio 打开工程自动同步。

## 3. 签名

使用 `hap-sign-tool.jar`（SDK 的 `toolchains/lib/` 下）：

```bash
java -jar <SDK>/23/toolchains/lib/hap-sign-tool.jar sign-app \
  -keyAlias "openharmony application release" \
  -signAlg SHA256withECDSA \
  -mode localSign \
  -appCertFile <证书链.pem> \
  -profileFile <profile.p7b> \
  -keystoreFile <OpenHarmony.p12> \
  -keystorePwd 123456 -keyPwd 123456 \
  -inFile entry-default-unsigned.hap \
  -outFile entry-default-signed.hap
```

子命令是 `sign-app`（不是 `sign-hap`）。更换证书重装前先 `hdc uninstall com.example.calculator`，
否则会报 sign info inconsistent。

## 4. 安装到板子

```bash
hdc install -r entry-default-signed.hap
hdc shell aa start -a EntryAbility -b com.example.calculator
```

`hdc` 请用与设备系统匹配的版本（SDK 23 的 `toolchains/hdc.exe`）。

## 5. 从 API 9 适配到 API 23 的改动

- `build-profile.json5`：改用 `products[].runtimeOS / compileSdkVersion / compatibleSdkVersion /
  targetSdkVersion`（app 级 `compileSdkVersion` 已不允许），并加上 `buildModeSet`。
- `oh-package.json5`、`hvigor/hvigor-config.json5`：新增 `modelVersion: "6.0.0"`，去掉
  `hvigorVersion` / 旧式 `dependencies`。
- `entry/src/main/module.json5`：`srcEntrance` → `srcEntry`（新 schema 必填）。
- `Index.ets`：18 处按键回调由表达式体 `() => this.xxx()` 改成块体 `() => { this.xxx() }`，
  满足 ArkTS `arkts-no-implicit-return-types`。
- 其余业务代码（排盘库 `ets/libs/`、DeepSeek 直连、隐藏触发逻辑）未改动。

## 6. 隐藏算命入口（开发/验收用）

计算器状态下直接键入：

- 10 位「生日 + 时辰」：`2005031703` = 2005-03-17 03 时
- 12 位「生日 + 时分」：`200503170257` = 2005-03-17 02:57

再按 `=`：本地排盘 → 直连 DeepSeek → 全屏命书页。输入满 8 位纯数字后按 `%` 可切换乾造/坤造。
阅读页点正文放大/缩小，按 `C` 或 `×` 返回。其余输入一律按普通计算器处理。

> 源码中内嵌的 DeepSeek API Key 仅供测试，不要对外分发或公开仓库。
