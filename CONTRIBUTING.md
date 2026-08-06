# 贡献指南

感谢参与 Until。私库 `main` 是产品开发源，公共仓库只接收经过安全检查的发布内容。

## 开始前

```powershell
.\scripts\install_git_hooks.ps1
git config --get core.hooksPath
```

提交前请运行：

```powershell
.\scripts\public_repo_guard.ps1 -AllTracked
```

## 开发约定

- 产品规则、跨平台字段和验收标准以 `packages/contract/` 与 `docs/development/CROSS_PLATFORM_STANDARD.md` 为准。
- Android、iOS、HarmonyOS 分别使用平台原生实现；修改功能时同步更新对应平台文档和测试样例。
- 不提交签名文件、密码、Token、`local.properties`、构建产物或真实用户数据。
- 提交信息使用简短、明确的英文前缀，例如 `feat:`, `fix:`, `docs:`, `test:`, `release:`。

## Pull Request

请说明变更目的、受影响的平台、测试方式和已知限制。涉及 UI 时附上截图或录屏；涉及权限、日历、通知或 Widget 时说明授权/拒绝路径。

## 发布

版本发布前必须完成平台测试、全量安全扫描，并使用同一份 release 签名材料生成安装包。发布流程见 `docs/release/PRIVATE_TO_PUBLIC_SYNC.md`。
