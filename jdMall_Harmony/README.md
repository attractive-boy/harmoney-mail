# 前言
 高仿某东商城harmony版本，个人学习harmony项目

1. 鸿蒙官方状态管理
2. 网络使用@ohos/axios进行封装
3. 使用node项目mock服务端接口(mock_server目录)
4. 目前实现了首页、分类、购物车、我的

* ### 同款Android Kotlin版本（https://github.com/GuoguoDad/jd_mall）
* ### 同款Flutter版本（https://github.com/GuoguoDad/jd_mall_flutter）

# 鸿蒙简介
  鸿蒙系统（HarmonyOS）是华为公司自主研发的一款面向全场景的分布式操作系统。该系统基于微内核架构设计，其核心优势在于通过分布式软总线技术，打破单一设备局限，实现手机、平板、电脑、智能家居等多设备间的无缝协同和自由流转，为用户提供“万物互联”的智慧体验。纯血鸿蒙从底层内核到应用生态彻底摆脱对安卓的依赖，成为继苹果iOS和安卓之后的全球第三大移动操作系统。

# ArkTS
1. ArkTS是一种设计用于构建高性能应用的编程语言。它在继承TypeScript语法的基础上进行了优化，以提供更高的性能和开发效率。
2. TypeScript是在JavaScript基础上通过添加类型定义扩展而来的，ArkTS则是TypeScript的进一步扩展。
3. ArkTS的一大特性是它专注于低运行时开销(强类型语言)。
4. ArkTS提供与TypeScript和JavaScript的无缝互通。

# 开发环境
DevEco Studio 6.0.2 Release  
HarmonyOS 6.0.2  
mock_server nodejs: v18.20.6

# 启动mock_server
1. cd mock_server
2. 执行 npm i 安装依赖
3. npm run mock

# 效果

| 首页                                     | 分类                                        | 购物车                                   |
|-----------------------------------------|---------------------------------------------|-----------------------------------------|
| <img src="images/home.gif" width="200"> | <img src="images/category.gif" width="200"> | <img src="images/cart.gif" width="200"> | 


| 我的                                     | 
|-----------------------------------------|
| <img src="images/mine.gif" width="200"> | 


# 第三方框架

| 库                        | 功能         |
|--------------------------|------------|
| **@ohos/axios**          | **网络框架**   |
| **@pura/harmony-utils**  | **工具库**    |
| **@ohos/imageknife**     | **图片显示**   |
| **@pura/harmony-dialog** | **弹窗组件**   |

# 声明

⚠️本APP仅限于学习交流使用，请勿用于其它商业用途

⚠️项目中使用的图片及字体等资源如有侵权请联系作者删除

⚠️如使用本项目代码造成侵权与作者无关

# 命令行运行本项目（结合 Spring Boot 后端）

## 1. 后端（Spring Boot + Azure MySQL）

- 代码路径：`servers`
- 命令：
  - 进入目录：`cd ../servers`
  - 启动：`./gradlew bootRun`
- 默认端口：`8091`
- 已配置 Azure MySQL 数据库连接（`jd_mall`）。

## 2. 前端（鸿蒙 jdMall_Harmony）命令行环境

- DevEco Studio 安装路径：`/Applications/DevEco-Studio.app`
- 关键工具：
  - hvigorw：`/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw`
  - ohpm：`/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm`
  - hdc：`/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc`
- SDK 根目录：
  - `DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk`

建议在 shell 中配置环境变量（可写入 `~/.zshrc`）：

```bash
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
export PATH="$PATH:/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin"
export PATH="$PATH:/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin"
export PATH="$PATH:/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains"
```

验证命令：

```bash
hvigorw --version --accept-license
ohpm --version
hdc list targets
```

## 3. 前后端地址对齐

- 后端地址：`http://本机IP:8091`
- 鸿蒙前端配置文件：
  - `common/src/main/ets/constants/EnvConstants.ets`
- 当前配置示例：

```ts
export class EnvConfig {
  static readonly baseUrl: string = 'http://192.168.5.10:8091'
}
```

如 IP 变动，只需修改 `baseUrl`。

## 4. 构建与安装 common shared 模块

进入鸿蒙项目根目录：

```bash
cd /Users/licheng/Desktop/harmoney-mail/jdMall_Harmony
```

安装依赖（首次或依赖更新后）：

```bash
ohpm install --all
```

构建 shared 模块 `common` 的 HSP：

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
hvigorw assembleHsp --mode module -p common
```

构建结果关键路径：

```text
common/build/default/outputs/default/common-default-unsigned.hsp
```

## 5. 构建与安装 entry 入口模块

构建入口模块 `entry` 的 HAP：

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
hvigorw assembleHap --mode module -p entry
```

构建结果关键路径：

```text
entry/build/default/outputs/default/entry-default-unsigned.hap
```

安装 shared 模块和入口 HAP 到模拟器（需确保模拟器已启动）：

```bash
hdc install common/build/default/outputs/default/common-default-unsigned.hsp
hdc install entry/build/default/outputs/default/entry-default-unsigned.hap
```

看到输出包含 `install bundle successfully.` 即为成功。

## 6. 启动应用到模拟器前台

包名与入口 Ability：

- 包名：`com.lucifer.jdmall`
- Ability：`EntryAbility`

启动命令：

```bash
hdc shell aa start -d 0 -b com.lucifer.jdmall -a EntryAbility
```

出现 `start ability successfully.` 表示模拟器已打开本应用，前端会连到本机 Spring Boot 后端。

/usr/sbin/lsof -ti tcp:8091 | xargs kill -9 || true