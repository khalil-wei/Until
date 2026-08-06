# 待到 / Until

源代码采用 [MIT License](LICENSE)。Until/待到名称、应用图标、截图和其他品牌素材不随源代码许可证授权，第三方依赖仍以各自许可证为准。

`待到 / Until` 是一款本地优先的倒计时日历工具，用于记录生日、纪念日和自定义重要日期。仓库包含 iOS、HarmonyOS 和 Android 三套原生实现；各端独立构建与发布，共用产品规则、验收定义、测试样例规划和设计资源。

当前工程和 target 仍使用 `CountdownEvents` 命名，产品名使用 `待到 / Until`。

## 当前状态与文档规则

- 当前三端能力状态以[三端功能矩阵](packages/contract/feature-matrix.md)为唯一记录。
- 功能完成定义以[多端开发标准](docs/development/CROSS_PLATFORM_STANDARD.md)为准。
- 产品规则、数据字段、平台限制和验收要求分别位于 `packages/contract/`。
- “忽略/恢复导入日历事件”仅为 iOS 平台特性；HarmonyOS 的遗留入口待清理，Android 不提供此能力。
- 除多语言资源、英文商店文案和对外合规文本外，项目文档使用中文。完整导航见[文档索引](docs/README.md)。

## 快速开始

### Android

安装 JDK 21 与 Android SDK 后：

```powershell
cd apps/android
.\gradlew.bat testDebugUnitTest assembleDebug
```

调试 APK 位于 `apps/android/app/build/outputs/apk/debug/app-debug.apk`。环境、功能和签名说明见[安卓工程说明](apps/android/README.md)。

如需面向开源用户提供官网下载的正式 Android APK，请按[开源与官网下载发布](docs/release/OPEN_SOURCE_DOWNLOAD.md)生成已签名的下载包与校验文件；不要分发调试 APK。

首次将仓库设为公开前，请先执行[公开仓库安全清单](docs/release/PUBLIC_REPOSITORY_SECURITY.md)中的扫描与 Git Hook 安装步骤。

完整的私有仓库、公共镜像、自动同步、Release 和泄漏应急流程见[开源与公共发布总清单](docs/release/OPEN_SOURCE_OPERATIONS_CHECKLIST.md)。

### iOS

在 macOS 安装 Xcode 后：

1. 打开[CountdownEvents.xcodeproj](apps/ios/CountdownEvents.xcodeproj)。
2. 在 Xcode 顶部选择 `CountdownEvents` scheme。
3. 选择 iPhone 模拟器或真机并运行。

完整步骤见[iOS 调试指南](docs/development/IOS_XCODE_GUIDE.md)。也可以在仓库根目录运行：

```sh
sh scripts/mac_debug_check.sh
```

### HarmonyOS

使用 DevEco Studio 打开 `apps/harmony/UntilHarmony/`。环境和构建说明见[鸿蒙开发指南](docs/development/harmony/DEV_GUIDE.md)，当前执行进度见[鸿蒙进度](apps/harmony/PROGRESS.md)。

## 仓库结构

```text
CountdownCalendar/
├── apps/                         三端原生应用工程
│   ├── android/                  Kotlin + Jetpack Compose + Glance
│   ├── harmony/                  ArkTS + ArkUI + Form Kit
│   └── ios/                      SwiftUI + WidgetKit
├── packages/
│   ├── contract/                 产品规则、能力矩阵、数据模型与验收标准
│   ├── localization/             共享文案源与生成资源的预留位置
│   ├── test-fixtures/            平台无关的 JSON 测试样例
│   └── assets/                   设计令牌、图标与商店素材源文件
├── docs/                         产品、开发、发布和商店文档
├── scripts/                      本地检查、资源生成和发布辅助脚本
└── PROJECT_GUIDELINES.md         项目维护约定
```

共享包不包含 Swift、ArkTS 或 Kotlin 运行时代码。各端将产品规则分别实现为本地代码；本地化生成链路和共享样例的三端测试接入仍待后续完善。

## 核心能力

- 手动新增、编辑、详情查看和按来源删除倒计时事件。
- 公历、农历、2 月 29 日规则、搜索、分类筛选和今天/即将到来分组。
- 系统日历读取与 App 创建事件的写入、更新、删除；真机状态见功能矩阵。
- 当天、提前 1/3/7 天的本地提醒。
- iOS Widget、HarmonyOS 服务卡片、Android Glance 桌面组件。
- 简体中文与英文，以及不改变业务状态的低频彩蛋。

## iOS 配置提示

当前 iOS 配置：

- App Bundle ID：`com.khalil.until`
- Widget Bundle ID：`com.khalil.until.widget`
- App Group：`group.com.khalil.until`

如更换开发者账号前缀，需要同步更新 Xcode target、[App entitlements](apps/ios/CountdownEvents/CountdownEvents.entitlements)、[Widget entitlements](apps/ios/CountdownEventsWidget/CountdownEventsWidget.entitlements)和[共享存储服务](apps/ios/Shared/Services/SharedDataService.swift)。
