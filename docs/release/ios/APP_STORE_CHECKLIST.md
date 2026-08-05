# iOS 应用市场上架检查清单

本文档用于跟踪 CountdownEvents 从开发完成到 App Store 上架的准备事项。

## 1. 账号与项目配置

- [ ] 注册并激活 Apple Developer Program。
- [ ] 在 App Store Connect 创建 App。
- [ ] 确认最终 App 名称。
- [ ] 确认最终 Bundle ID。
- [ ] 确认 Widget Bundle ID。
- [ ] 确认 App Group ID。
- [ ] 在 Xcode 中替换占位 Bundle ID。
- [ ] 在两个 target 中配置同一个 Signing Team。
- [ ] 在两个 target 中开启 App Groups capability。
- [ ] 确认最低系统版本为 iOS 17.0。

建议命名：

- App Bundle ID：`com.yourname.countdownevents`
- Widget Bundle ID：`com.yourname.countdownevents.widget`
- App Group ID：`group.com.yourname.countdownevents`

## 2. 发布前功能检查

- [ ] 首次启动能请求完整日历访问权限。
- [ ] 授权后能读取系统日历中的生日与纪念日事件。
- [ ] 拒绝权限后仍可新增、查看、删除本地倒计时。
- [ ] 新增事件可选择是否同步到系统日历。
- [ ] 没有完整日历权限时，同步开关禁用并展示本地保存说明。
- [ ] 新增和编辑事件可选择本地通知提醒提前量。
- [ ] 关闭提醒或删除事件后不会继续发送对应本地通知。
- [ ] 搜索能正确过滤事件。
- [ ] 分类筛选能正确切换全部、生日、纪念日、自定义。
- [ ] 滑动删除不会在搜索或筛选状态下删错事件。
- [ ] 2 月 29 日事件在非闰年能显示下一个有效闰年日期。
- [ ] Widget 能读取 App Group 数据。
- [ ] 小尺寸 Widget 展示最近 1 个事件。
- [ ] 中尺寸 Widget 展示最多 3 个事件。
- [ ] App 与 Widget 支持简体中文和英文。

## 3. 真机测试

- [ ] iPhone 真机安装成功。
- [ ] 日历权限弹窗文案正确。
- [ ] 通知权限弹窗只在用户开启提醒时出现。
- [ ] 授权、拒绝、重新授权三个路径均验证。
- [ ] 系统日历新增测试事件后，App 能导入。
- [ ] App 新增同步事件后，系统日历能看到每年重复事件。
- [ ] Widget 添加到桌面后展示正确数据。
- [ ] 新增/删除事件后 Widget 能刷新。
- [ ] 切换系统语言为简体中文后文案正确。
- [ ] 切换系统语言为英文后文案正确。

## 4. App Store Connect 信息

- [ ] App 名称。
- [ ] 副标题。
- [ ] 描述。
- [ ] 关键词。
- [ ] 分类。
- [ ] 年龄分级。
- [ ] 支持 URL。
- [ ] 隐私政策 URL。
- [ ] 版权信息。
- [ ] App Review 联系信息。
- [ ] App Review 备注，说明日历权限用途和无权限可本地使用。

## 5. 隐私与合规

- [ ] 发布隐私政策页面。
- [ ] App Store 隐私营养标签填写完成。
- [ ] 确认不收集、不上传用户日历数据。
- [ ] 确认 Widget 只读取 App Group 中的倒计时数据。
- [ ] 确认本地通知只在设备端排程，不上传提醒数据。
- [ ] 确认没有第三方 SDK 或统计服务。
- [ ] 确认没有账号系统、广告、内购或订阅。

## 6. 视觉与素材

- [ ] App Icon。
- [ ] Launch Screen。
- [ ] App Store 截图。
- [ ] Widget 截图。
- [ ] 简体中文截图。
- [ ] 英文截图。
- [ ] 截图文案与实际功能一致。

## 7. 构建与上传

- [ ] `sh scripts/mac_debug_check.sh` 通过。
- [ ] Xcode Debug 真机构建通过。
- [ ] Xcode Archive 成功。
- [ ] Validate App 成功。
- [ ] Upload to App Store Connect 成功。
- [ ] Build 在 App Store Connect 处理完成。

## 8. TestFlight

- [ ] 添加内部测试人员。
- [ ] 准备 TestFlight 测试说明。
- [ ] 内部测试通过。
- [ ] 如需要，开启外部测试。
- [ ] 收集反馈并修复阻断问题。

## 9. App Review

- [ ] 选择准备发布的 build。
- [ ] 填写版本更新说明。
- [ ] 填写审核备注。
- [ ] 提交审核。
- [ ] 如被拒，记录原因并修复。
- [ ] 审核通过后选择手动或自动发布。

## 10. 上线后

- [ ] 监控崩溃和用户反馈。
- [ ] 关注日历权限相关评论。
- [ ] 关注通知权限和提醒时间相关反馈。
- [ ] 关注 Widget 刷新相关反馈。
- [ ] 规划下一个版本：自定义提醒时间、已隐藏事件管理、Widget 样式配置。
