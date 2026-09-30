# WeChat Play XWeb Guard — 中文详细说明

**作者：E3N**  
**模块 ID：`wechat_xweb_guard`**  
**当前公开版本：v1.1.0**

## 1. 这个模块解决什么问题

Google Play 版微信在部分版本中会使用独立的 XWeb/Pinus 内核。该内核位于微信私有数据目录中，体积较大，某些清理操作可能把它误判为缓存并删除。

在已验证的设备上，XWeb 1160289 被清理后，会出现类似以下现象：

- 微信诊断页不再显示正在使用 XWeb 1160289；
- 小程序/网页首次打开时出现“正在升级”；
- `app_xweb_data/xweb_1160289` 消失或不完整；
- 微信暂时回退到系统 WebView；
- 即使微信版本本身没有变化，也需要重新安装 XWeb 才能恢复原来的 Pinus 内核。

WeChat Play XWeb Guard 的目标非常窄：**防止一个已经正常安装并验证可用的 XWeb 运行时因为误清理而丢失。**

它不是：

- 微信破解器；
- XWeb 下载器；
- XWeb 版本强制器；
- 微信降级工具；
- FCM 修复模块；
- LSPosed/Zygisk Hook 模块。

## 2. 当前兼容范围

目前代码只允许在以下已验证组合上进行自动恢复：

| 项目 | 已验证值 |
|---|---|
| 微信包名 | `com.tencent.mm` |
| 微信版本 | Google Play 8.0.77 |
| versionCode | `3141` |
| XWeb | `1160289` |
| ABI | `arm64-v8a` |
| Root | Magisk 兼容环境 |

这是有意为之的安全边界。

当微信升级后，如果 `versionCode != 3141`，模块不会把旧的 XWeb 1160289 强行恢复到新微信中。这样可以避免“为了防误删，反而把旧内核灌进未知版本”。

## 3. 为什么 Release ZIP 里没有 240 MB 的 XWeb

私有测试原型曾经把本机 XWeb 静态文件直接保存在模块目录中，快照约 240 MB。

公开版 v1.1.0 改成：

> **代码公开，XWeb 快照由用户自己的设备本地生成。**

GitHub 仓库和 Release ZIP 不包含：

- `libxwebcore.so`
- `base.zip`
- XWeb 的 `base.apk`
- 微信 APK
- 任何聊天数据
- 任何账号数据

安装模块时，如果本机已经存在健康的 XWeb 1160289，模块从该本地安装生成快照并保存到：

```text
/data/adb/wechat_xweb_guard/core_1160289.tar
```

对应 SHA256 清单：

```text
/data/adb/wechat_xweb_guard/core_1160289.sha256
```

因此模块更新本身不会重新分发微信/XWeb 私有二进制文件。

## 4. 工作原理

### 4.1 安装阶段

`customize.sh` 会：

1. 检查设备 ABI 是否为 `arm64-v8a`；
2. 建立私有工作目录 `/data/adb/wechat_xweb_guard`；
3. 如果从旧私有原型升级，则尝试迁移旧本地快照；
4. 检查当前微信是否为 versionCode 3141；
5. 检查 XWeb 1160289 是否完整；
6. 完整时只打包白名单中的静态运行文件；
7. 为快照生成 SHA256。

如果安装时 XWeb 已经被删除，模块不会凭空生成一个假快照。它会保持安装状态，等待以后微信自行重新安装出健康 XWeb 后再进行本地捕获。

### 4.2 健康检查

当前实现使用已验证文件结构和大小检查：

```text
extracted_xwalkcore/libxwebcore.so = 135166832 bytes
apk/base.apk                           = 33171682 bytes
zip/base.zip                           = 70436321 bytes
```

同时要求：

```text
extracted_xwalkcore/filelist.config
extracted_xwalkcore/dummy.dat
```

存在且非空。

这些检查不是通用的“所有 XWeb 版本识别器”，而是对当前已验证目标的版本锁。

### 4.3 事件监听

模块启动后由 `watch.sh` 启动 BusyBox `inotifyd`。

正常情况下它不是高频轮询器，而是等待内核文件系统事件。

主要监听：

```text
.../com.tencent.mm/
.../com.tencent.mm/app_xweb_data/
.../xweb_1160289/
.../xweb_1160289/extracted_xwalkcore/
.../xweb_1160289/apk/
.../xweb_1160289/zip/
```

当关键文件/目录被删除或移动时，`event.sh` 触发 `repair.sh`。

目录被恢复后 inode 会变化，因此事件处理器会让当前 `inotifyd` 退出，再由外层 watcher 自动重新订阅新目录。

## 5. 自动恢复会做什么

只有同时满足以下条件时才会恢复：

1. 微信数据目录仍存在；
2. `MicroMsg` 仍存在，用于区分正常应用数据与主动“清除全部数据”；
3. 微信 versionCode 仍为 `3141`；
4. XWeb 静态核心确实缺失/不完整；
5. 私有快照存在；
6. 快照 SHA256 校验通过。

恢复时：

- 不杀微信进程；
- 不清聊天记录；
- 不改 FCM token；
- 不修改系统全局属性；
- 不关闭 SELinux；
- 不安装 LSPosed/Zygisk Hook；
- 不覆盖 `Default` WebView Profile；
- 不覆盖 `dex/oat` 运行状态；
- 只恢复静态 XWeb 运行文件。

如果 XWeb 版本配置已经被微信清空，且静态文件恢复成功，模块会恢复：

```xml
<boolean name="using_core_version_1160289" value="true" />
```

这个行为只在 versionCode 3141 + 已验证本地快照的条件下发生。

## 6. 隐私设计

快照脚本使用**白名单**，不会直接 tar 整个 XWeb 目录。

允许进入快照的内容只有：

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

并再次检查 tar 内容，如果出现以下路径关键词则拒绝生成：

```text
Default
Profile
Cookies
History
Login
MicroMsg
```

因此快照不是微信备份，也不是账号备份。

## 7. 安装

1. 在 GitHub Releases 下载：

```text
WeChat-Play-XWeb-Guard-v1.1.0.zip
```

2. 在 Magisk 中选择“从本地安装”。
3. 查看安装日志：
   - 如果显示 `Local XWeb 1160289 snapshot is ready`，说明保护快照已经建立；
   - 如果显示没有捕获到健康 XWeb，模块会先保持被动。
4. 重启。

## 8. Magisk Action

模块提供 Action 诊断入口。

它会显示：

- 当前微信 versionCode；
- XWeb 1160289 是否健康；
- 私有保护快照是否存在且校验通过；
- watcher 是否运行；
- 最近恢复日志。

如果当前核心健康但快照缺失，Action 会尝试建立快照。

如果核心缺失但快照有效，Action 会执行一次恢复检查。

## 9. 日志与手工检查

日志：

```sh
su -c 'cat /data/adb/wechat_xweb_guard/guard.log'
```

检查快照：

```sh
su -c 'cd /data/adb/wechat_xweb_guard && /data/adb/magisk/busybox sha256sum -c core_1160289.sha256'
```

检查 watcher：

```sh
su -c 'cat /data/adb/wechat_xweb_guard/watcher.pid'
```

检查微信实际版本：

```sh
su -c "dumpsys package com.tencent.mm | grep -E 'versionCode=|versionName='"
```

检查 XWeb 使用标记：

```sh
su -c 'cat /data_mirror/data_ce/null/0/com.tencent.mm/shared_prefs/xweb_using_core_version.xml'
```

## 10. 耗电

健康状态下核心监听主要依赖 `inotifyd` 阻塞等待文件事件，不需要每秒扫描 XWeb 目录。

外层 watcher 只有在：

- 开机后 CE 数据尚未解锁；
- `inotifyd` 因目录重建而退出；

这类情况下使用短暂 sleep/re-arm。

所以模块设计目标不是“常驻轮询保护”，而是“事件驱动 + 开机完整性检查”。

## 11. 卸载

从 Magisk 卸载模块并重启。

`uninstall.sh` 会删除：

```text
/data/adb/wechat_xweb_guard/
```

包括本地保护快照、日志和 PID 状态。

**不会删除微信当前正在使用的 XWeb。**

因此卸载后微信保持当时的状态，只是失去后续防误删/自动恢复能力。

## 12. 升级微信后的行为

如果微信升级后 versionCode 变化：

- 模块不会继续恢复 1160289；
- 不会主动降级微信；
- 不会强制修改新版微信的 XWeb；
- 旧快照留在私有目录，直到用户卸载模块或未来版本明确增加新的兼容规则。

这比直接对 XWeb 目录使用 `chmod` 或 `chattr +i` 更保守：不会阻止微信自己正常替换/升级内核。

## 13. 为什么不用 chmod/chattr

`chmod` 无法可靠阻止具有 root 权限的清理器删除文件，同时可能让微信自身无法正常写入。

`chattr +i` 更强，但可能：

- 阻止微信更新内核；
- 阻止正常目录替换；
- 给应用升级留下不可预期状态；
- 仍可能被 root 清理脚本主动解除。

本模块选择“允许微信正常管理自己的目录，误删后从本机快照恢复”的策略。

## 14. 已验证场景

私有原型在实际设备上已经多次记录到自动恢复事件，包括单文件删除和目录级删除测试。

公开版 v1.1.0 保留相同恢复模型，但把快照从模块包改为**本地生成并保存在独立私有目录**，避免公开发布第三方二进制。

## 15. 风险与限制

- Root 模块始终存在系统风险，请先确保有可用的 Magisk 恢复手段。
- 当前兼容规则非常具体，不保证适用于其他微信/XWeb 版本。
- 微信内部目录结构属于未公开实现，未来可能变化。
- 如果用户主动清除了整个微信应用数据，本模块不会尝试重建它。
- 如果快照本身损坏，SHA256 校验失败后模块拒绝恢复。
- 模块不能替代微信自己的 XWeb 安装/升级机制。

## 16. 开源与第三方声明

本仓库源码采用 MIT License。

微信、WeChat、XWeb 及相关二进制属于其各自权利方。本仓库不包含这些二进制文件，也不提供第三方 XWeb 下载。

本项目与腾讯、微信、Google、小米无隶属、合作或官方背书关系。
