# 鸿蒙版开发指南

鸿蒙工程位置：

```text
apps/harmony/UntilHarmony/
```

## 当前状态

仓库内包含完整的 DevEco Studio Stage 模型工程、ArkTS 页面与业务逻辑、日历与提醒适配、服务卡片和本地化资源。

工程配置已按 DevEco Studio 6.1.1 / HarmonyOS 6.1.1(24) 调整，Debug 构建已通过；真机日历、提醒、服务卡片、签名和发布状态见[三端功能矩阵](../../../packages/contract/feature-matrix.md)与[鸿蒙进度](../../../apps/harmony/PROGRESS.md)。

## DevEco 打开步骤

1. 安装 DevEco Studio。
2. 打开 `apps/harmony/UntilHarmony/`。
3. 等待 IDE 同步 hvigor 和 SDK 配置。
4. 检查 `build-profile.json5` 中的 SDK、签名和 product 配置。
5. 选择 `entry` 模块运行到模拟器或真机。
6. 如果 IDE 自动生成或修复工程元数据，提交修正后的配置文件。

## DevEco Studio 6.1.1 导入提示迁移

DevEco Studio 6.1.1 首次打开工程时，可能提示“工程结构及配置需要升级后才能使用”。如果出现该提示：

1. 优先点击底部“迁移助手”里的 `迁移到 6.1.1`。
2. 迁移后确认以下配置存在：
   - `oh-package.json5` 中 `modelVersion` 为 `6.1.1`。
   - `hvigor/hvigor-config.json5` 中 `modelVersion` 为 `6.1.1`。
   - `build-profile.json5` 中 `compileSdkVersion` 为 `6.1.1(24)`。
   - `build-profile.json5` 中 `targetSdkVersion` 为 `6.1.1(24)`。
3. 点击 `File -> Sync and Refresh Project` 重新同步。
4. 如果迁移助手反复提示，关闭 DevEco 后重新打开 `apps/harmony/UntilHarmony/`。

## ohpm 拉取 Hvigor 404

如果同步时出现 `@ohos/hvigor` 或 `@ohos/hvigor-ohos-plugin` 从 `https://ohpm.openharmony.cn/ohpm/` 拉取失败：

1. 确认根 `oh-package.json5` 不包含 `@ohos/hvigor` 和 `@ohos/hvigor-ohos-plugin`。
2. DevEco Studio 6.1.1 已自带 Hvigor 和 `hvigor-ohos-plugin`，应用工程不需要通过 ohpm 安装它们。
3. 确认根 `hvigorfile.ts` 使用 `appTasks`，`entry/hvigorfile.ts` 使用 `hapTasks`。
4. 重新执行 `File -> Sync and Refresh Project`。

## 命令行构建验证

DevEco Studio 6.1.1 在 Windows 下可使用 IDE 自带的 Node、Java 和 Hvigor 做本地验证：

```powershell
$env:NODE_HOME = "D:\software\DevEco Studio\tools\node"
$env:DEVECO_SDK_HOME = "D:\software\DevEco Studio\sdk"
$env:JAVA_HOME = "D:\software\DevEco Studio\jbr"
$env:PATH = "$env:NODE_HOME;$env:JAVA_HOME\bin;$env:PATH"

& "D:\software\DevEco Studio\tools\ohpm\bin\ohpm.bat" install --all --registry https://ohpm.openharmony.cn/ohpm/ --strict_ssl true
& "D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.bat" test --no-daemon --stacktrace
& "D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap --no-daemon --stacktrace
& "D:\software\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap --mode module -p product=production -p module=entry@default -p buildMode=release --no-daemon --stacktrace
```

注意：`DEVECO_SDK_HOME` 应指向 `D:\software\DevEco Studio\sdk`，不要指向 `sdk\default`。

## 修改包名后仍启动旧包名

如果运行日志里仍出现旧包名，例如 `Launching com.khalil.until.harmony`，但 `AppScope/app.json5` 已经改成 `com.khalil.until`：

1. 点击 `File -> Sync and Refresh Project`。
2. 重新选择运行配置里的 `entry` 模块。
3. 如果仍然启动旧包名，关闭 DevEco Studio 后重新打开工程。
4. 仍未恢复时，删除本地 IDE 缓存 `.idea/.deveco/project.cache.json` 后重新打开工程。

当前正式包名为 `com.khalil.until`。

## 首次需要重点验证

- `EntryAbility` 能否正常加载 `pages/Index`。
- 首页能否读取本地持久化数据，并在无数据时显示空状态。
- `TextInput`、`Button`、`List`、`ForEach` 等 ArkUI 语法是否符合当前 SDK。
- `PreferencesCountdownEventStore` 的 `@kit.ArkData` 导入和调用是否符合当前 SDK。
- `module.json5` 的资源引用、页面配置和 ability 配置是否有效。
- SVG 图标资源是否可作为应用图标使用；如不支持，替换为 PNG。

## 维护与验收顺序

1. 使用当前工具链完成 Debug 构建与单元测试。
2. 在真机验证 Preferences 持久化、升级兼容和空数据行为。
3. 验证新增、编辑、详情、删除、日历和提醒流程。
4. 验证服务卡片添加、刷新、跨日更新和路由。
5. 完成中英文、无障碍、减少动态效果与小屏回归。
6. 配置仓库外正式签名，生成并验证 Release 包。

## QA 清单

基础与数据：

- [ ] 真机启动、空数据、持久化和升级兼容通过。
- [ ] 搜索、分类、今天/即将到来分组和倒计时颜色正确。
- [ ] 新增、编辑、取消、删除和重启后的结果正确。
- [ ] 公历、农历、2 月 29 日和未来日期计算正确。

日历与提醒：

- [ ] 首次使用时按需请求日历权限，拒绝后本地事件仍可用。
- [ ] 读取生日/纪念日，以及 App 创建事件的写入、更新和删除正确。
- [ ] 导入事件按来源执行“仅从 App 移除”或“从日历删除”，不提供忽略/恢复入口。
- [ ] 当天和提前 1/3/7 天提醒可送达；删除或修改后正确取消和重排。

服务卡片与体验：

- [ ] 小、中、大尺寸展示真实数据，空状态正确。
- [ ] App 内事件变化和次日跨日后卡片刷新。
- [ ] 卡片路由、新增入口和事件详情跳转正确。
- [ ] 中文、英文、日期区域格式、字体放大、减少动态效果和无障碍语义通过。

发布前：

- [ ] 隐私说明与实际权限一致。
- [ ] 华为应用市场截图、文案、正式签名和 Release 包完成。
