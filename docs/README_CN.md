# WeChat Play XWeb Guard — 中文详细说明

**作者：E3N**  
**模块 ID：`wechat_xweb_guard`**  
**版本：v1.2.0**

## 1. 解决的问题

部分 Google Play 版微信会使用独立 XWeb/Pinus 内核。XWeb 位于微信私有数据目录中，体积较大，某些 Root 清理脚本或激进清理工具可能把它误判为可删除缓存。

在实机上，XWeb 1160289 被清理后曾出现：

- 微信诊断页不再使用 XWeb 1160289；
- 小程序/网页重新出现“正在升级”；
- `app_xweb_data/xweb_1160289` 消失或不完整；
- 微信暂时回退系统 WebView；
- 需要重新安装 XWeb 才能恢复原来的 Pinus 内核。

本模块的职责很窄：**保留一份已校验的 XWeb 1160289 静态运行快照，并在误删后自动恢复。**

## 2. v1.2.0 与 v1.1.0 的关键区别

v1.2.0 做了两个重要调整：

1. **Release ZIP 直接内置 XWeb 1160289 静态快照。**
2. **微信升级到其他 build 后，不再因为 versionCode 变化自动停止恢复。**

因此其他用户安装 v1.2.0 后，即使当前微信的 XWeb 已经被清空，也可以直接恢复，不需要 APKM，也不需要先让微信自己重新下载一遍 XWeb。

## 3. 已验证参考环境

| 项目 | 已验证值 |
|---|---|
| 包名 | `com.tencent.mm` |
| 微信 | Google Play 8.0.77 |
| versionCode | `3141` |
| XWeb | `1160289` |
| ABI | `arm64-v8a` |
| Root | Magisk 兼容环境 |

这里的 `3141` 是**实机验证参考值**。

从 v1.2.0 开始，如果微信 versionCode 发生变化：

- 模块会记录“当前 build 未验证”；
- 默认仍继续恢复 XWeb 1160289；
- 不主动降级微信；
- 是否继续使用由用户自己判断。

如果用户希望采用严格策略，可执行：

```sh
su -c 'touch /data/adb/wechat_xweb_guard/strict_build'
```

此时只有 versionCode 3141 会自动恢复。

恢复默认跨 build 模式：

```sh
su -c 'rm -f /data/adb/wechat_xweb_guard/strict_build'
```

## 4. 内置快照与脱敏

Release ZIP 内置：

```text
assets/core_1160289.tar
assets/core_1160289.sha256
```

快照 SHA256：

```text
09347ca1fb5b250fd79460b2b22083400046599fa5714af93124f2d1507f7619
```

快照经过路径级检查，只包含 10 个 XWeb 静态条目：

```text
apk/base.apk
extracted_xwalkcore/
extracted_xwalkcore/dummy.dat
extracted_xwalkcore/libxwebcore.so
extracted_xwalkcore/libWXAMSDK.so
extracted_xwalkcore/libffmpeg.so
extracted_xwalkcore/media_player_extension.apk
extracted_xwalkcore/filelist.config
extracted_xwalkcore/reslist.config
zip/base.zip
```

明确不包含：

- `Default`
- `Profile`
- `Cookies`
- `History`
- `Login`
- `MicroMsg`
- FCM token
- 微信聊天记录
- 微信账号信息

所以这里所谓“脱敏”不是修改 XWeb 二进制，而是**确保发布快照里根本没有用户数据目录或凭据**。

维护者 E3N 已声明拥有这些 XWeb 二进制文件的公开再分发授权。

## 5. 安装时发生什么

`customize.sh` 会：

1. 检查设备 ABI 是否为 `arm64-v8a`；
2. 建立：

   ```text
   /data/adb/wechat_xweb_guard/
   ```

3. 读取内置 `core_1160289.sha256`；
4. 对内置 `core_1160289.tar` 计算 SHA256；
5. 哈希不一致则中止安装；
6. 哈希一致后把快照移动到私有保护目录；
7. 再次校验移动后的文件；
8. 只保留一份长期快照，避免安装后双倍占用空间。

最终保护文件：

```text
/data/adb/wechat_xweb_guard/core_1160289.tar
/data/adb/wechat_xweb_guard/core_1160289.sha256
```

## 6. 事件监听

模块由 `watch.sh` 启动 BusyBox `inotifyd`。

它主要监听：

```text
.../com.tencent.mm/
.../com.tencent.mm/app_xweb_data/
.../xweb_1160289/
.../xweb_1160289/extracted_xwalkcore/
.../xweb_1160289/apk/
.../xweb_1160289/zip/
```

健康状态下不需要每秒扫描目录。大部分时间 `inotifyd` 阻塞在内核中等待文件系统事件。

当关键目录或文件被删除/移动时，`event.sh` 触发 `repair.sh`。

目录恢复后 inode 会改变，因此事件处理器会让旧 `inotifyd` 退出，外层 watcher 自动重新订阅恢复后的新目录。

## 7. 自动恢复条件

默认模式下，满足以下条件即可恢复：

1. 微信应用数据目录仍存在；
2. `MicroMsg` 仍存在，用于避免“用户主动清空整个微信数据后模块又开始重建”；
3. XWeb 1160289 静态运行文件缺失或不完整；
4. 保护快照存在；
5. 快照 SHA256 校验通过；
6. 如果启用了 `strict_build`，则当前微信 versionCode 必须为 3141。

默认没有第 6 条 build 限制。

## 8. 恢复内容

恢复只覆盖静态文件：

```text
apk/base.apk
zip/base.zip
extracted_xwalkcore/dummy.dat
extracted_xwalkcore/filelist.config
extracted_xwalkcore/reslist.config
extracted_xwalkcore/libxwebcore.so
extracted_xwalkcore/libWXAMSDK.so
extracted_xwalkcore/libffmpeg.so
extracted_xwalkcore/media_player_extension.apk
```

不会覆盖：

- WebView `Default` Profile；
- Cookies/History；
- dex/oat 运行状态；
- 微信聊天；
- FCM 身份；
- 微信账号信息。

恢复时也不会为了“保险”而强制停止微信。

## 9. XWeb 使用标记

如果静态文件恢复成功，但微信的 XWeb 使用记录已经被清空，模块会恢复：

```xml
<boolean name="using_core_version_1160289" value="true" />
```

在未验证微信 build 上执行时，日志会明确记录 warning。

## 10. 安装

从 GitHub Releases 下载：

```text
WeChat-Play-XWeb-Guard-v1.2.0.zip
```

然后：

1. Magisk → 模块；
2. 从本地安装；
3. 选择 ZIP；
4. 确认安装日志出现：

   ```text
   Bundled XWeb 1160289 snapshot verified and installed.
   ```

5. 重启。

无需准备 APKM。

## 11. Magisk Action

模块 Action 会显示：

- 当前微信 versionCode；
- build 是否属于已验证参考；
- 未验证 build 时是否仍允许恢复；
- XWeb 1160289 是否健康；
- 快照是否通过 SHA256；
- watcher PID；
- 最近恢复日志。

## 12. 手工诊断

查看日志：

```sh
su -c 'cat /data/adb/wechat_xweb_guard/guard.log'
```

验证保护快照：

```sh
su -c 'cd /data/adb/wechat_xweb_guard && /data/adb/magisk/busybox sha256sum -c core_1160289.sha256'
```

查看 watcher：

```sh
su -c 'cat /data/adb/wechat_xweb_guard/watcher.pid'
```

查看微信版本：

```sh
su -c "dumpsys package com.tencent.mm | grep -E 'versionCode=|versionName='"
```

查看 XWeb 使用标记：

```sh
su -c 'cat /data_mirror/data_ce/null/0/com.tencent.mm/shared_prefs/xweb_using_core_version.xml'
```

## 13. 耗电

设计目标是“事件驱动”，不是“常驻高频扫描”。

正常情况下 `inotifyd` 在内核等待文件事件，不持续读 XWeb 文件。

外层 watcher 只在以下场景短暂 sleep/re-arm：

- 开机后 CE 数据尚未可用；
- 被监听目录恢复后 inode 变化；
- `inotifyd` 退出，需要重新订阅。

## 14. 为什么不用 chmod/chattr

`chmod` 对 Root 清理器并不可靠，而且可能妨碍微信自己读写 XWeb。

`chattr +i` 虽然更强，但可能：

- 阻止微信正常替换 XWeb；
- 阻止新版微信升级内核；
- 造成应用目录不可预期状态；
- 被 Root 清理脚本主动解除。

本模块选择“允许微信正常管理目录，误删后自动恢复”的方案。

## 15. 微信升级后的行为

v1.2.0 默认策略：

- versionCode 变化：继续恢复 1160289；
- Action/日志：提示 UNVALIDATED；
- 用户确认可用：无需操作；
- 用户发现不兼容：可以禁用模块、卸载模块，或者启用 `strict_build`。

模块不会自行替用户判断“新 build 一定兼容”或“一定不兼容”。

## 16. 卸载

从 Magisk 卸载并重启。

卸载脚本会停止 watcher，并删除：

```text
/data/adb/wechat_xweb_guard/
```

包括内置快照迁移后的本地副本、校验文件、日志和 PID。

**不会删除微信当前已经安装好的 XWeb。**

## 17. 已验证测试

开发过程中已经验证：

- 单个 XWeb 关键文件移除 → 自动恢复；
- 整个 `zip` 子目录移除 → 自动恢复；
- 恢复后 watcher 自动重新订阅；
- XWeb 静态文件 MD5/内部清单一致；
- 1160289 在微信进程中实际映射加载；
- FCM 信息未因 XWeb 恢复而变化；
- 公开快照 tar 不含用户 Profile/聊天目录；
- Release 构建时再次验证快照 SHA256 和路径白名单。

## 18. 授权与第三方声明

本项目守护代码采用 MIT License。

内置 XWeb 1160289 属于第三方软件。维护者 **E3N 声明拥有这些 XWeb 二进制文件的公开再分发授权**。

MIT License 只覆盖本项目自己编写的守护代码，不自动改变第三方 XWeb 二进制原有权利归属。

本项目与腾讯、微信、Google、小米无隶属或官方背书关系。
