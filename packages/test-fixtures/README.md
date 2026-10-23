# 共享测试样例

此目录中的 JSON 样例应保持平台无关，用于逐步覆盖三端一致的业务规则。

现有或规划中的样例：

- `countdown-cases.json`
- `dedupe-cases.json`
- `lunar-date-cases.json`
- `reminder-cases.json`
- `recurrence-cases.json`：Android、HarmonyOS 规则测试已接入，覆盖每月/每周、短月、闰月、跨年及未来首次日期；iOS XCTest 包含同组日期用例，待 Mac 执行。
- `calendar-rule-cases.json`：Android 已接入，覆盖系统日历简单规则识别和复杂规则拒绝，当前仅 Android 提供对应导入保护。
- `easter-egg-cases.json`

当前样例文件已存在，但三端测试尚未统一读取它们。新增可数据化复现的规则时，应先补充样例，并逐步在 iOS、HarmonyOS 与 Android 测试中接入。
