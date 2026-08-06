# 私库开发到公共仓库发布

私库 `CountdownCalendar` 是唯一开发源，公共仓库 `Until` 只用于公开源码和 Release。不要把公共仓库设为默认 `origin`，也不要在公共仓库直接开发后再反向合并到私库。

## 一次性配置

```powershell
cd D:\personal\CountdownCalendar
git remote add public https://github.com/wdlami/Until.git
git fetch public
.\scripts\install_git_hooks.ps1
```

## 每次发布前

```powershell
git switch main
git pull --ff-only origin main
.\scripts\publish_public.ps1
```

脚本默认只预览，不会推送。确认差异、文件列表和版本号无误后：

```powershell
.\scripts\publish_public.ps1 -Publish
```

如果两个仓库历史不一致，脚本会拒绝推送。只有确认私库全部历史都可以公开时，才允许一次性对齐：

```powershell
.\scripts\publish_public.ps1 -ForceAlign -Publish
```

该操作会先在公共仓库创建 `archive-before-sync-时间` 备份分支，再使用 `--force-with-lease` 更新公共 `main`。如果私库历史不能公开，不要使用此选项，应采用干净快照发布。

## 标签和 Release

同历史镜像模式下，在私库创建并推送标签，再推送到公共仓库：

```powershell
git tag -a android-v2.0.3 -m "Android v2.0.3"
git push origin android-v2.0.3
git push public android-v2.0.3
```

然后在公共仓库创建 GitHub Release，上传签名 APK 和 `.sha256` 文件。签名证书、密码、`signing.properties` 和 keystore 永远不进入 Git。

## 安全边界

- `origin` 只指向私库，`public` 只指向公共镜像。
- 推送前运行 `public_repo_guard.ps1 -AllTracked`。
- 当前安全脚本扫描的是现有 Git 追踪文件；首次公开前还必须对全部 Git 历史执行密钥扫描。
- 如果历史中出现过密码或 Token，应先撤销/轮换，再决定是否重写历史。
