# 安卓版开发说明

Android 原生版使用 Kotlin、Jetpack Compose、DataStore、Calendar Provider、AlarmManager/Notification 与 Glance Widget。当前能力状态见[三端功能矩阵](../../packages/contract/feature-matrix.md)，通用规则见[跨平台产品契约](../../packages/contract/README.md)。

## 环境与构建

- JDK 21
- Android SDK Platform 35
- Android Build Tools 35.0.0
- Gradle 8.11.1（仓库已包含 Wrapper）

在 `local.properties` 中配置本机 SDK：

```properties
sdk.dir=D\:\\android-sdk
```

运行：

```powershell
.\gradlew.bat testDebugUnitTest assembleDebug
```

调试 APK 位于 `app/build/outputs/apk/debug/app-debug.apk`。

## 当前源码结构

源码位于 `app/src/main/java/com/khalil/until/`：

```text
├─ MainActivity.kt                 Compose 入口、路由和页面协调
├─ UntilApplication.kt             仓库与提醒初始化
├─ core/
│  ├─ model/                       事件模型
│  └─ domain/                      倒计时、农历和提醒规则
├─ data/                           DataStore 存储与事件仓库
├─ platform/
│  ├─ calendar/                    Calendar Provider 适配
│  └─ reminder/                    通知与重排适配
├─ ui/
│  ├─ components/                  事件行与展示模型
│  ├─ screens/                     首页、表单、详情
│  └─ theme/                       Compose 主题、颜色与排版
└─ widget/                         Glance 桌面组件
```

Composable 只使用事件模型、页面状态和回调；存储、日历与提醒逻辑不得复制进 UI。仓库数据变化负责驱动首页、详情和组件刷新。

## 功能与路由

- 首页今天/即将到来分组、搜索、筛选和下拉刷新。
- 公历/农历年度日期与 2 月 29 日规则。
- 每年、每月、每周重复；月重复跳过缺少对应日期的月份，农历闰月参与；周重复从所选日期起每 7 天。旧记录保持每年重复。
- 新增、编辑、详情和按来源删除确认。
- 系统日历导入及年度事件创建、更新、删除。
- 系统日历导入识别简单年/月/周规则；复杂规则跳过并提示；只改标题或备注时保留系统时间与重复规则。
- 当天/提前 1、3、7 天本地通知，重启后恢复排程。
- `until://add` 与 `until://event/{id}` 深链。
- 桌面组件按真实宽高及字体预算自适应后续事件数量，支持拖动调整；倒计时数字与单位同排避免裁切。
- 中文、英文、深色模式与低频彩蛋。

## UI 约定

实际主题位于 `ui/theme/`：页面背景 `#F5F7FA`、表面 `#FFFFFF`、主色 `#0A9B86`、主文字 `#1C1C1E`、辅助文字 `#636366`、危险色 `#C44761`；页面水平边距 20dp、卡片圆角 22dp、控件圆角 12dp、最小点击区域 44dp。

首页依次为标题与新增、搜索、分类、权限降级、今天、即将到来和空状态/事件列表。事件卡片保持“类型、标题/日期/来源、倒计时”三层信息。表单字段顺序与多端标准一致，保存中禁止重复提交。Android 可使用 Material 日期选择器、权限弹窗和系统返回手势，但不得改变产品术语、日期规则和排序。

组件要求：小尺寸 1 条，其他尺寸按可用空间展示主事件和后续事件；增宽或增高不得减少条目，宽松布局仅在保留条目时启用；空状态打开 App 新增，不使用测试数据；事件变化与跨日后重新读取数据。

维护 UI 时先核对[多端开发标准](../../docs/development/CROSS_PLATFORM_STANDARD.md)和[设计令牌](../../packages/assets/design/design-tokens.json)，视觉规则放在 `ui/theme/` 或可复用组件，不在页面临时硬编码。至少覆盖 360dp、393dp、600dp，中文/英文、字体放大和深色模式。

## 发布签名

调试包由 Android 调试证书签名。商店发布包必须使用项目所有者长期保管的 release keystore；不要提交 keystore、口令或 `signing.properties`。创建正式签名后运行 `assembleRelease`，并在真机完成通知、精确闹钟、日历权限、组件和 OEM 后台限制回归。

面向开源用户提供下载时，复制 `signing.properties.example` 为本机 `signing.properties` 后运行仓库根目录的 `scripts/build_android_download_release.ps1`。该流程会生成已签名 APK 和 SHA-256 校验文件；完整说明见[开源与官网下载发布](../../docs/release/OPEN_SOURCE_DOWNLOAD.md)。
