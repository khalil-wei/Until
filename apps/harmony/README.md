# 鸿蒙应用

此目录存放 `待到 / Until` 的 HarmonyOS 版本，开发进度见[PROGRESS.md](PROGRESS.md)。

技术栈：

- ArkTS
- ArkUI
- 服务卡片 / Form Kit
- HarmonyOS Calendar Kit 与本地提醒能力

使用 DevEco Studio 打开：

```text
apps/harmony/UntilHarmony/
```

当前 HarmonyOS 版本已上架华为应用市场。Debug 包仍可构建、安装和启动；真机验收、日历、提醒和服务卡片的真实系统行为，以[三端功能矩阵](../../packages/contract/feature-matrix.md)和[进度文档](PROGRESS.md)为准。

`2.0.2` 已发布。当前 `2.1.1` 候选版本使用 `versionCode 12`，在首用激活闭环的基础上，统一新增、编辑和详情页视觉，完善系统深色模式，并重做服务卡片的信息层级与自适应布局；详细方案见[HarmonyOS 2.1.1 留存激活与卡片体验改造方案](../../docs/product/HARMONY_RETENTION_ACTIVATION_PLAN.md)。

后续版本发布前需要：

1. 在真机完成升级、日历、提醒、服务卡片和视觉回归，并回填当前版本的发布后验证结果。
2. 在 `build-profile.json5` 中确认生产 SDK 与签名配置。
3. 生成并验证签名后的发布包。

签名材料不存放在 Git 中。请在 DevEco Studio 本机配置 Debug 和生产签名；如曾提交过签名凭据，应在下一次发布前轮换。
