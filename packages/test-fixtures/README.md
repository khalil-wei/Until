# 共享测试样例

此目录中的 JSON 样例应保持平台无关，用于逐步覆盖三端一致的业务规则。

现有或规划中的样例：

- `countdown-cases.json`
- `dedupe-cases.json`
- `lunar-date-cases.json`
- `reminder-cases.json`
- `easter-egg-cases.json`

当前样例文件已存在，但三端测试尚未统一读取它们。新增可数据化复现的规则时，应先补充样例，并逐步在 iOS、HarmonyOS 与 Android 测试中接入。
