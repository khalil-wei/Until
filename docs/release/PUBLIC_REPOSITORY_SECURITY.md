# 公开 GitHub 仓库安全清单

公开仓库可用于让任何人查看源码和下载 GitHub Release 附件。私有仓库的 Release 仅对拥有仓库访问权的用户开放，不能作为面向公众的 APK 下载页。

## 已纳入仓库的防护

- `.gitignore` 忽略签名证书、发布 Profile、`signing.properties`、`local.properties`、构建产物和本机环境文件。
- `.githooks/pre-commit` 会在提交前扫描暂存区，阻止常见签名文件、私钥、GitHub Token 和明文签名口令。
- `scripts/public_repo_guard.ps1 -AllTracked` 可在首次公开前扫描当前受 Git 追踪的全部文件。

首次克隆或首次公开前，在仓库根目录执行：

```powershell
.\scripts\install_git_hooks.ps1
.\scripts\public_repo_guard.ps1 -AllTracked
```

提交前也可手动运行：

```powershell
.\scripts\public_repo_guard.ps1
```

## 仍需人工确认的事项

- 不上传 release keystore、`.p12`、`.p7b`、`.jks`、`.keystore`、证书、口令、API token、`signing.properties` 或 `local.properties`。
- 只在 GitHub Secrets 保存 CI 所需的签名内容；不要把 Secret 值打印到构建日志。
- 如果凭据曾经进入过任何公开分支、Release 附件、Issue、Actions 日志或聊天记录，立即轮换；删除当前文件不能消除历史泄露。
- 首次公开前，在 GitHub 仓库的 Security 页面开启 Secret scanning、Push protection 和 Dependabot alerts（可用性取决于仓库方案）。
- 公开前人工检查 `git log --all` 与待上传附件；APK 必须由 release keystore 签名，私钥绝不随 APK 一同上传。
