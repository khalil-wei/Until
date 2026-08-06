# 开源与公共发布总清单

这份清单用于把私有开发仓库安全地发布为 `wdlami/Until` 公共镜像，并持续提供可验证的 Release 下载包。开发源仍然是私有仓库 `CountdownCalendar`；公共仓库只接收经过守卫检查的当前源码快照。

## 一、首次公开前

- [ ] 确认公共仓库名称、维护者、许可证和品牌边界。源码使用 MIT；Until/待到名称、图标、截图和其他品牌素材不自动获得 MIT 授权。
- [ ] 确认私有仓库 `origin` 指向开发仓库，公共仓库单独使用 `public` remote；不要把公共仓库设为默认开发源。
- [ ] 检查工作区和未跟踪文件：

  ```powershell
  git status --short --untracked-files=all
  git remote -v
  ```

- [ ] 安装提交前 Git Hook 并扫描当前所有受 Git 跟踪的文件：

  ```powershell
  .\scripts\install_git_hooks.ps1
  .\scripts\public_repo_guard.ps1 -AllTracked
  ```

- [ ] 检查整个 Git 历史、所有分支、标签和待上传的 Release 附件。当前守卫主要保护索引文件，不能替代历史泄漏审计；如历史曾出现 Token、密码、签名文件或用户数据，先撤销/轮换凭据，再决定是否重写历史。
- [ ] 确认 `.gitignore` 已覆盖 `local.properties`、`signing.properties`、`.env*`、keystore、证书、私钥、APK/AAB/IPA 和构建目录；示例配置只能使用占位值。
- [ ] 确认仓库中的隐私政策、第三方许可证、联系方式和支持入口已更新。

## 二、公共仓库设置

- [ ] 公共仓库默认分支为 `main`，打开 Issues 和 Discussions 前先确认没有私密信息。
- [ ] 开启 Dependabot alerts、Secret scanning / push protection（如果仓库方案支持），并启用 Actions 权限的最小范围。
- [ ] 配置分支保护：要求 Pull Request、状态检查和维护者审查；禁止把 `PUBLIC_REPO_TOKEN` 写入代码、Issue、Release 或日志。
- [ ] 公共仓库不要包含私库专用的 `.github/workflows/publish-public.yml`；快照脚本会自动排除它。

## 三、自动同步配置

私有仓库的 `.github/workflows/publish-public.yml` 会在 `main` 推送后运行。只需在私有仓库配置一个细粒度 Token：

1. GitHub → 私有仓库 → **Settings → Secrets and variables → Actions**。
2. 新建 Secret：`PUBLIC_REPO_TOKEN`。
3. Token 只授权 `wdlami/Until` 一个仓库的 **Contents: Read and write**。
4. 不要把 Token 写入 remote URL、脚本文件或本地配置并提交。
5. 手动触发一次 **Actions → Publish public snapshot → Run workflow**，确认公共仓库出现 `sync: publish private snapshot ...` 提交。

每次发布后核对：

```powershell
git fetch public main
git log -1 --oneline public/main
```

如果 Actions 失败，先查看失败 Job 的第一条错误。常见原因是 Secret 名称/权限错误、公共分支保护拒绝推送或构建/守卫检查失败；修复后重新运行，不要手动把私有历史推送到公共仓库。

## 四、日常开发与 Release

- [ ] 在私有仓库完成代码、测试、文档和功能矩阵更新。
- [ ] 推送私有 `main`，等待 **Quality** 和 **Publish public snapshot** 均成功。
- [ ] 在公共仓库确认同步提交和文件差异，再创建不可变版本标签/Release。
- [ ] Android Release 使用长期保存的同一份 release keystore；上传 APK 和 `.sha256` 校验文件，不上传 keystore、密码或 `signing.properties`。
- [ ] iOS 使用 TestFlight/App Store 的签名与隐私材料；HarmonyOS 使用 DevEco/AppGallery 的签名与商店资料。三端发布清单见同目录的各平台文档。
- [ ] Release 说明写明版本号、支持系统、已知限制、隐私政策、源码地址和校验值。

## 五、回滚与泄漏应急

- [ ] 同步内容错误：在私有仓库修复后重新推送，让公共仓库产生新的快照提交；不要直接改写公共 `main`。
- [ ] Token/密码/签名材料泄漏：立即撤销或轮换凭据，暂停自动同步，删除公共 Release/分支中的附件，并评估 Git 历史重写。
- [ ] Android 签名材料泄漏：停止发布旧签名包，按 Android 平台政策处理密钥升级；仅删除文件无法消除历史风险。
- [ ] 安全漏洞不要发到公共 Issue，按 [SECURITY.md](../../SECURITY.md) 私下报告。

## 权威文档

- [私库到公共仓库同步](PRIVATE_TO_PUBLIC_SYNC.md)
- [公共快照同步说明](PUBLIC_SNAPSHOT_SYNC.md)
- [公共仓库安全清单](PUBLIC_REPOSITORY_SECURITY.md)
- [开源下载与 Release](OPEN_SOURCE_DOWNLOAD.md)
