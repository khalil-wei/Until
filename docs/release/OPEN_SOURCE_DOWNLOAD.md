# 开源与官网下载发布

本项目可以将源码公开，并通过官网或代码托管平台的 Release 页面提供 Android APK 下载。这是**独立分发**，不等同于在应用商店上架。

## 对外发布的最小产物

- 源码仓库与开源许可证。
- 已签名的 `Until-Android-release.apk`。
- 同名 `SHA-256` 校验文件。
- 版本说明、隐私政策链接、支持邮箱或反馈入口。
- 安装说明：Android 用户需从可信来源下载；系统可能要求用户确认安装外部来源的应用。

不要发布 Debug APK，也不要发布 Android App Bundle（`.aab`）供用户手动安装。

## 生成 Android 下载包

1. 将 `apps/android/signing.properties.example` 复制为 `apps/android/signing.properties`。
2. 填入项目所有者长期保管的 Android release keystore 信息。该文件已被 Git 忽略，禁止提交。
3. 在仓库根目录执行：

```powershell
.\scripts\build_android_download_release.ps1
```

脚本会先运行 Android 单元测试，再生成签名 APK，并在 `apps/android/release/` 写入 APK 及其 SHA-256 文件。加 `-SkipTests` 只能用于已完成同一提交测试后的重打包，不可替代发布前测试。

## 发布到下载页

每次发布请创建不可修改的版本标签，例如 `android-v2.0.2`，并上传以下文件：

- `Until-Android-release.apk`
- `Until-Android-release.apk.sha256`
- 本版本更新说明

下载页必须清楚列出应用包名 `com.khalil.until`、版本号、发布日期、SHA-256、隐私政策和源码地址。更新包必须持续使用同一 release 签名证书，否则已安装用户不能覆盖升级。

## 开源前安全检查

- 所有 keystore、密码、证书、发布 Profile、`signing.properties` 和本机路径均不得进入 Git。
- 已暴露或曾提交的签名口令必须轮换；仅从 Git 删除文件不足以消除泄露风险。
- HarmonyOS 正式签名材料由本机安全配置或 CI 密钥注入；公开仓库的 `build-profile.json5` 不得包含生产口令。
- 对中国大陆公开提供下载前，请根据实际的下载站点、主体和服务内容，向接入服务商或主管部门确认 APP 备案及公示要求。开源不豁免隐私与分发合规义务。

## Android 开发者验证

Android 正在逐步推进开发者身份验证和包名登记。即使当前只从官网分发，也建议使用个人身份完成 Android Developer Console 验证并登记 `com.khalil.until` 与 release 签名证书，以避免后续设备安装限制影响用户。具体覆盖地区和时间以 Android 官方政策为准。
