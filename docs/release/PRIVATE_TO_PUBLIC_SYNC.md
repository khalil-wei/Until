# 私库开发到公共仓库发布

私库 `CountdownCalendar` 是唯一开发源，公共仓库 `Until` 只用于公开源码和 Release。不要把公共仓库设为默认 `origin`，也不要在公共仓库直接开发后再反向合并到私库。

## 一次性配置

```powershell
cd D:\personal\CountdownCalendar
git remote add public https://github.com/wdlami/Until.git
git fetch public
.\scripts\install_git_hooks.ps1
```

## 当前推荐模式：干净快照

当前仓库使用快照模式。私库的提交历史、私有工作流和被忽略的签名文件不会进入公共仓库。日常发布使用：

```powershell
git switch main
git pull --ff-only origin main
.\scripts\publish_public_snapshot.ps1
```

脚本默认只预览，不会推送。确认差异、文件列表和版本号无误后：

```powershell
.\scripts\publish_public_snapshot.ps1 -Publish
```

私有仓库的 `.github/workflows/publish-public.yml` 已配置为在 `main` 推送后自动执行同一套快照发布。手动脚本主要用于本地预览、故障排查或没有 Actions 时的应急发布。

## 标签和 Release（快照模式）

不要把私库创建的标签推送到公共仓库；标签可能指向私有提交并暴露私有历史。应等待公共同步完成后，在公共 `main` 的同步提交上创建标签，或直接在公共仓库的 Release 页面生成标签：

```powershell
git fetch public main
$publicSha = (git rev-parse public/main).Trim()
git push public "${publicSha}:refs/tags/android-v2.0.3"
```

然后在公共仓库创建 GitHub Release，上传签名 APK 和 `.sha256` 文件。签名证书、密码、`signing.properties` 和 keystore 永远不进入 Git。

## 安全边界

- `origin` 只指向私库，`public` 只指向公共镜像。
- 推送前运行 `public_repo_guard.ps1 -AllTracked`。
- 当前安全脚本扫描的是现有 Git 追踪文件；首次公开前还必须对全部 Git 历史执行密钥扫描。
- 如果历史中出现过密码或 Token，应先撤销/轮换，再决定是否重写历史。

## 仅限历史镜像模式的脚本

`scripts/publish_public.ps1` 用于两个仓库明确共享可公开历史的特殊场景。它不是当前快照发布的默认脚本；只有确认私库全部历史、所有标签和所有分支都可公开时，才可按以下方式一次性对齐：

```powershell
.\scripts\publish_public.ps1 -ForceAlign -Publish
```

该操作会先创建 `archive-before-sync-时间` 备份分支，再使用 `--force-with-lease` 更新公共 `main`。不确定时不要使用，继续采用快照模式。
