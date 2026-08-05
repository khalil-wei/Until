# macOS 调试指南

本文档按 **Xcode Version 26.3 (17C529)** 编写，用来帮助新手在 Mac 上打开、运行和排查 `CountdownEvents`。

`CountdownEvents` 是一个 iOS 倒计时日历 App，包含两个 target：

- `CountdownEvents`：主 App，负责读取日历、展示列表、添加和删除事件。
- `CountdownEventsWidget`：桌面小组件，负责从 App Group 读取主 App 保存的数据。

如果你刚接触 Xcode，可以先把 target 理解为“要编译出来的东西”。这个项目会编译出一个 App 和一个 Widget，所以很多配置需要两个 target 都设置一次。

## 1. 准备环境

### 必备条件

- macOS Sequoia 15.7 或更高版本。
- Xcode Version 26.3 (17C529)。
- iOS 17 或更高版本模拟器，或一台已连接的 iPhone。
- 一个 Apple ID。基础本地调试需要它；真机调试 App Groups 时，如果 Xcode 无法自动创建能力，可能需要加入 Apple Developer Program 的开发者账号。

### 确认 Xcode 版本

打开 macOS 的 Terminal，输入：

```sh
xcodebuild -version
```

正常情况下应看到类似输出：

```text
Xcode 26.3
Build version 17C529
```

如果输出的不是 Xcode 26.3，可能是命令行工具没有指向当前 Xcode。打开 Xcode 后，进入：

`Xcode` -> `Settings...` -> `Locations` -> `Command Line Tools`

选择 `Xcode 26.3` 对应的版本，然后重新运行 `xcodebuild -version`。

## 2. 第一次打开项目

1. 打开 Finder，进入项目根目录。
2. 双击 `apps/ios/CountdownEvents.xcodeproj`。
3. Xcode 打开后，左侧如果能看到 `CountdownEvents`、`CountdownEventsWidget`、`Shared` 等文件夹，说明工程加载成功。
4. Xcode 顶部工具栏左侧有一个 scheme 选择器，选择 `CountdownEvents`。
5. scheme 右侧是运行设备选择器，先选择一个 iOS 17+ Simulator，例如 `iPhone 16` 或类似名称的模拟器。

新手提示：不要直接打开某个 `.swift` 文件来运行项目。需要打开 `apps/ios/CountdownEvents.xcodeproj`，否则 Xcode 不知道整个 App、Widget、资源文件和签名配置之间的关系。

## 3. 首次签名配置

Xcode 调试 iOS App 时需要签名。模拟器通常更宽松，真机和 App Groups 必须配置正确。

### 3.1 登录 Apple ID

如果 Xcode 还没有登录账号：

1. 打开 `Xcode` -> `Settings...`。
2. 进入 `Accounts`。
3. 点击左下角 `+`。
4. 选择 `Apple ID` 并登录。

普通 Apple ID 通常可以用于模拟器和基础真机调试。如果你要在真机上完整验证 Widget 通过 App Group 读取主 App 数据，但 Xcode 提示无法创建 App Group、无法添加 capability 或 provisioning profile 不包含 App Groups，就需要使用已加入 Apple Developer Program 的开发者账号。

### 3.2 给主 App 选择 Team

1. 在左侧 Project Navigator 中，点击最上层蓝色项目图标 `CountdownEvents`。
2. 中间编辑区会出现 project 和 targets 列表。
3. 在 `TARGETS` 下面选择 `CountdownEvents`。
4. 打开 `Signing & Capabilities` tab。
5. 勾选 `Automatically manage signing`。
6. 在 `Team` 下拉框中选择你的账号或团队。

### 3.3 给 Widget 选择 Team

继续在同一个页面：

1. 在 `TARGETS` 下面选择 `CountdownEventsWidget`。
2. 打开 `Signing & Capabilities` tab。
3. 勾选 `Automatically manage signing`。
4. `Team` 选择和主 App 一样的账号或团队。

注意：主 App 和 Widget 建议使用同一个 Team。否则真机安装和 App Groups 容易失败。

## 4. Bundle ID 和 App Group

### 4.1 它们分别是什么

- Bundle ID：App 的唯一身份证。
- Widget Bundle ID：Widget 的唯一身份证，通常以主 App Bundle ID 为前缀。
- App Group：主 App 和 Widget 共享数据的“公共储物柜”。

这个项目默认使用占位值：

- App Bundle ID：`com.yourcompany.countdownevents`
- Widget Bundle ID：`com.yourcompany.countdownevents.widget`
- App Group：`group.com.yourcompany.countdownevents`

如果只是看代码，可以先不改。如果要真机调试，建议把 `yourcompany` 换成你自己的唯一前缀，例如：

- App Bundle ID：`com.khalil.countdownevents`
- Widget Bundle ID：`com.khalil.countdownevents.widget`
- App Group：`group.com.khalil.countdownevents`

### 4.2 修改 Bundle ID

主 App：

1. 点击项目图标 `CountdownEvents`。
2. 选择 target `CountdownEvents`。
3. 打开 `Signing & Capabilities`。
4. 找到 `Bundle Identifier`。
5. 改成你的主 App Bundle ID，例如 `com.khalil.countdownevents`。

Widget：

1. 选择 target `CountdownEventsWidget`。
2. 打开 `Signing & Capabilities`。
3. 找到 `Bundle Identifier`。
4. 改成 Widget Bundle ID，例如 `com.khalil.countdownevents.widget`。

Widget 的 Bundle ID 最好以主 App Bundle ID 开头，再加 `.widget`。例如主 App 是 `com.khalil.countdownevents`，Widget 就用 `com.khalil.countdownevents.widget`。

### 4.3 修改 App Group

两个 target 都需要启用同一个 App Group。

主 App：

1. 选择 target `CountdownEvents`。
2. 打开 `Signing & Capabilities`。
3. 如果看不到 `App Groups`，点击 `+ Capability`，搜索并添加 `App Groups`。
4. 在 `App Groups` 下添加你的 group id，例如 `group.com.khalil.countdownevents`。

Widget：

1. 选择 target `CountdownEventsWidget`。
2. 打开 `Signing & Capabilities`。
3. 添加或展开 `App Groups`。
4. 添加和主 App 完全一样的 group id。

“完全一样”很重要。少一个字符、大小写不同、主 App 和 Widget 不一致，Widget 都可能读不到数据。

### 4.4 同步修改代码和 entitlements

如果你改了 App Group，需要同步检查这些文件：

- `apps/ios/CountdownEvents/CountdownEvents.entitlements`
- `apps/ios/CountdownEventsWidget/CountdownEventsWidget.entitlements`
- `apps/ios/Shared/Services/SharedDataService.swift`

其中 `SharedDataService.swift` 里的 `appGroupID` 必须和 Xcode `Signing & Capabilities` 里添加的 App Group 一致。

可以在 Xcode 顶部菜单使用：

`Find` -> `Find in Project...`

搜索：

```text
group.com.yourcompany.countdownevents
```

把它替换成你的 App Group，例如：

```text
group.com.khalil.countdownevents
```

## 5. 在模拟器运行

模拟器适合快速检查 UI、列表、搜索、删除和本地数据逻辑。

1. 顶部 scheme 选择 `CountdownEvents`。
2. 设备选择一个 iOS 17+ Simulator。
3. 点击左上角三角形运行按钮，或按 `Cmd + R`。
4. 等待 Xcode 编译，模拟器会自动启动 App。
5. 首次启动时，如果出现日历权限弹窗，选择允许完整访问。

如果没有任何日历数据，这是正常的。模拟器里的 Calendar 通常是空的。你可以：

- 在模拟器中打开 Calendar App，手动添加一个包含 `生日`、`纪念日`、`birthday` 或 `anniversary` 的事件。
- 或直接在 CountdownEvents App 内手动新增一个倒计时事件。
- 或改用真机测试真实日历数据。

## 6. 在真机运行

真机更适合测试日历权限、App Group、Widget 刷新和系统行为。

1. 用数据线连接 iPhone。
2. iPhone 上选择信任这台 Mac。
3. Xcode 顶部设备选择器选择你的 iPhone。
4. 确认两个 target 都已经选择 Team，并且 Bundle ID/App Group 不再使用 `yourcompany` 占位值。
5. 按 `Cmd + R`。

如果 iPhone 提示不信任开发者：

1. 在 iPhone 打开 `Settings`。
2. 进入 `General` -> `VPN & Device Management`。
3. 找到你的开发者账号。
4. 点击 Trust。
5. 回到 Xcode 再运行一次。

## 7. 调试 Widget

Widget 不是单独存数据的。它通过 App Group 读取主 App 保存的事件。

### 7.1 添加 Widget

1. 先运行一次主 App。
2. 在主 App 中新增一个倒计时事件。
3. 回到 iPhone 或模拟器桌面。
4. 长按桌面空白处。
5. 点击左上角 `+`。
6. 搜索 `CountdownEvents`。
7. 添加小尺寸或中尺寸 Widget。

预期结果：

- 小尺寸显示最近 1 个事件。
- 中尺寸最多显示 3 个事件。
- 主 App 新增或删除事件后，Widget 会刷新。

### 7.2 Widget 没有更新时

按这个顺序排查：

1. 打开主 App，新增或删除一个事件，让 App 触发保存。
2. 等几秒后回到桌面看 Widget。
3. 长按 Widget，删除后重新添加。
4. 检查主 App 和 Widget 的 App Group 是否完全一致。
5. 检查 `SharedDataService.swift` 的 `appGroupID` 是否和 Xcode 配置一致。

WidgetKit 有自己的刷新节奏，不一定每次保存后都立即肉眼可见刷新。调试时删除后重新添加 Widget 是最直接的验证方式。

## 8. 看日志和断点

### 8.1 查看日志

Xcode 下方是调试区域。如果没看到，可以按：

```text
Cmd + Shift + Y
```

运行 App 后，下方 Console 会显示日志、权限错误、崩溃信息等。

### 8.2 设置断点

断点用于让 App 在某一行代码暂停，方便查看变量。

1. 打开一个 `.swift` 文件。
2. 在代码左侧行号附近点击一下。
3. 出现蓝色箭头就是断点。
4. 重新运行 App。
5. 当代码执行到这一行时，App 会暂停。

常用断点位置：

- `apps/ios/CountdownEvents/Services/CalendarService.swift`：排查日历读取和写入。
- `apps/ios/CountdownEvents/ViewModels/EventListViewModel.swift`：排查列表刷新、搜索、删除。
- `apps/ios/Shared/Services/SharedDataService.swift`：排查 App 和 Widget 共享数据。
- `apps/ios/CountdownEventsWidget/CountdownWidgetProvider.swift`：排查 Widget 时间线刷新。

### 8.3 看变量

App 在断点暂停后：

- 左下角 Variables View 可以看到当前变量。
- 下方 Console 可以输入 `po 变量名` 查看对象内容。

例如：

```lldb
po events
```

如果你只是想继续运行，点击顶部工具栏的继续按钮，或按 `Control + Cmd + Y`。

## 9. 命令行检查

如果 Xcode 界面报错太多，先用命令行确认工程是否能编译。

在 Terminal 进入项目根目录：

```sh
cd /Users/khalil/Documents/workspace/CountdownCalendar
```

运行仓库提供的检查脚本：

```sh
sh scripts/mac_debug_check.sh
```

该脚本会做三件事：

1. 打印当前 `xcodebuild` 版本。
2. 列出工程里的 schemes。
3. 执行一次 Debug 构建。

也可以手动运行：

```sh
xcodebuild -project apps/ios/CountdownEvents.xcodeproj -scheme CountdownEvents -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

如果这里能成功，说明项目基础编译没问题；剩下的问题通常集中在签名、真机权限、App Group 或运行时数据。

## 10. 功能验证清单

### 主 App

- 首次启动能弹出日历完整访问权限。
- 授权后能读取系统日历中含 `birthday`、`birthdays`、`生日`、`anniversary`、`anniversaries`、`纪念日` 的事件。
- 事件列表按剩余天数升序排序。
- 下拉刷新能重新读取日历数据。
- 搜索后滑动删除不会删错事件。
- 新建事件时，空名称不能保存。
- 开启同步后，系统日历里会创建每年重复的全天事件。
- 关闭同步时，事件只保存在本地共享数据中。

### Widget

- 安装主 App 后，能添加 `CountdownEventsWidget` 小组件。
- 小尺寸显示最近 1 个事件。
- 中尺寸显示最多 3 个事件。
- 主 App 新增/删除事件后，Widget 能刷新。
- 次日刷新后，倒计时天数能正确变化。

### 本地化

分别把系统语言切到简体中文和英文后验证：

- 主 App 文案跟随系统语言。
- Widget 文案跟随系统语言。
- 日历权限说明跟随系统语言。
- 日期显示跟随系统区域格式。
- 英文倒计时能正确显示 `day` / `days`。

## 11. 常见问题

### Xcode 顶部没有 `CountdownEvents` scheme

先确认你打开的是 `apps/ios/CountdownEvents.xcodeproj`，不是单个 Swift 文件。如果仍然没有，打开：

`Product` -> `Scheme` -> `Manage Schemes...`

确认 `CountdownEvents` 是否存在，并勾选 `Show`。

### Build Failed，但不知道看哪里

1. 按 `Cmd + 9` 打开 Report Navigator。
2. 点击最新一次 Build。
3. 展开红色错误。
4. 优先看第一条错误。

新手排错时不要从最后一条开始看。后面的错误经常是第一条错误引发的连锁反应。

### 真机签名失败

重点检查：

- 主 App 和 Widget 是否都选择了同一个 Team。
- `Automatically manage signing` 是否勾选。
- Bundle ID 是否唯一，是否还在使用 `yourcompany`。
- Widget Bundle ID 是否以主 App Bundle ID 为前缀。
- App Groups 是否在 Apple 账号能力中创建成功。
- 当前账号是否支持 App Groups。若 Xcode 明确提示 App Groups capability 或 provisioning profile 不可用，需要换成已加入 Apple Developer Program 的账号。

如果 Xcode 提示无法注册 Bundle ID，通常说明这个 Bundle ID 已经被别人使用。换一个更独特的前缀即可。

### App Group 读取不到数据

检查三个地方是否完全一致：

- Target `CountdownEvents` 的 App Group。
- Target `CountdownEventsWidget` 的 App Group。
- `apps/ios/Shared/Services/SharedDataService.swift` 里的 `appGroupID`。

如果刚改完 App Group，建议删除设备上的旧 App 后重新运行，避免旧容器数据影响判断。

### 首次启动没有日历权限弹窗

可能原因：

- 之前已经授权或拒绝过。
- 当前流程还没有触发读取日历。
- 模拟器权限状态被缓存了。

可以在模拟器或真机里进入：

`Settings` -> `Privacy & Security` -> `Calendars`

找到 `CountdownEvents`，手动检查权限。需要重新测试首次弹窗时，可以删除 App 后重新安装。

### 模拟器没有日历数据

模拟器日历通常为空。手动打开模拟器里的 Calendar App 添加测试事件，或改用真机验证系统日历读取。

建议测试事件标题包含这些关键词之一：

- `生日`
- `纪念日`
- `birthday`
- `anniversary`

### Widget 没有显示事件

先确认主 App 里能看到事件。然后检查：

- 是否已添加桌面 Widget。
- App Group 是否一致。
- 主 App 新增/删除事件后是否回到桌面等待刷新。
- 删除 Widget 后重新添加是否恢复。

### 本地化资源不生效

确认以下资源被加入对应 target：

- `apps/ios/CountdownEvents/Resources/en.lproj`
- `apps/ios/CountdownEvents/Resources/zh-Hans.lproj`
- `apps/ios/CountdownEventsWidget/Resources/en.lproj`
- `apps/ios/CountdownEventsWidget/Resources/zh-Hans.lproj`

当前 Xcode 工程已配置这些资源。如果你手动重建工程，需要在 File Inspector 里重新勾选 target membership。

### 命令行能编译，Xcode 里不能运行

通常是运行设备、签名或权限问题：

- 换一个 iOS 17+ 模拟器再试。
- 清理构建缓存：`Product` -> `Clean Build Folder...`。
- 真机调试时确认 iPhone 已解锁并信任 Mac。
- 确认 Xcode 顶部设备不是 `Any iOS Device`，而是具体模拟器或真机。

## 12. 推荐调试顺序

第一次调试时建议按这个顺序来：

1. 用模拟器跑通主 App。
2. 手动新增一个倒计时事件。
3. 验证列表、搜索、删除。
4. 添加 Widget，验证 Widget 能读到主 App 数据。
5. 换真机运行，验证真实日历权限。
6. 在真机桌面添加 Widget，验证刷新。
7. 最后再测试中英文语言切换。

这样可以把问题拆开：先确认代码能跑，再确认共享数据，最后确认真机权限和系统集成。
