# 文档索引

文档按“状态、契约、开发、产品、发布”分工，避免重复维护同一信息。

## 权威来源

| 内容 | 文档 |
| --- | --- |
| 三端当前能力、待验收项与平台特性 | [三端功能矩阵](../packages/contract/feature-matrix.md) |
| 产品规则、数据模型、平台边界与验收要求 | [跨平台产品契约](../packages/contract/README.md) |
| 功能完成定义、UI、数据、文案、测试与发布标准 | [多端开发标准](development/CROSS_PLATFORM_STANDARD.md) |
| 产品定位、用户流程和后续需求 | [产品文档](product/PRODUCT_DOCUMENT.md) |

## 开发指南

- [iOS 调试指南](development/IOS_XCODE_GUIDE.md)
- [鸿蒙开发指南与 QA 清单](development/harmony/DEV_GUIDE.md)
- [安卓开发说明](../apps/android/README.md)
- [鸿蒙工程说明](../apps/harmony/README.md)与[执行进度](../apps/harmony/PROGRESS.md)

## 产品与发布

- [隐私政策](product/PRIVACY_POLICY.md)：包含对外英文版本和三端平台差异。
- [HarmonyOS 2.0.3 留存激活改造方案](product/HARMONY_RETENTION_ACTIVATION_PLAN.md)：记录无线上埋点前提下的首用状态机、权限时机、本地旅程状态与验收标准。
- [HarmonyOS 服务卡片核心化改造方案](product/HARMONY_CARD_CORE_PLAN.md)：记录首页常驻入口、卡片中心、逐卡配置、系统配置入口与迁移验收标准。
- iOS：[上架清单](release/ios/APP_STORE_CHECKLIST.md)、[内测计划](release/ios/TESTFLIGHT_PLAN.md)
- Android：[发布清单](release/android/PLAY_RELEASE_CHECKLIST.md)
- 开源与官网直装：[下载包发布流程](release/OPEN_SOURCE_DOWNLOAD.md)
- 开源与公共发布：[总操作清单](release/OPEN_SOURCE_OPERATIONS_CHECKLIST.md)
- 公开 GitHub 仓库：[安全清单](release/PUBLIC_REPOSITORY_SECURITY.md)
- HarmonyOS：[应用市场与版本清单](release/harmony/APPGALLERY_CHECKLIST.md)、[商店文案](release/harmony/STORE_COPY.md)

## 维护规则

- 当前状态只改功能矩阵；规则只改契约；开发完成条件只改多端开发标准。
- 平台文档只记录构建、真机验收和发布任务，不重复定义产品规则。
- 项目、开发、契约、测试和发布说明使用中文；多语言资源、英文商店文案与对外合规文本可保留英文。
