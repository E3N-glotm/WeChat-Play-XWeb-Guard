# WeChat Play XWeb Guard · 微信 XWeb 内核保护与恢复

**语言：简体中文（当前） | [English](README_EN.md)**

用于保护 **Google Play 版微信**的 XWeb/Pinus `1160289` 静态运行时。部分清理工具可能误删微信私有 XWeb 目录，导致小程序与网页出现“正在升级”，或退回系统 WebView；本模块保存快照，并在需要时恢复。

**当前版本：v1.2.4** · [下载 Release](https://github.com/E3N-glotm/WeChat-Play-XWeb-Guard/releases) · [完整中文技术文档](docs/README_CN.md)

## 工作方式

- Release ZIP 自带**经路径级隐私检查**的 XWeb `1160289` 静态快照及 SHA-256 文件；可在原 XWeb 已被清理的情况下恢复。
- 使用 BusyBox `inotifyd` 监听关键文件删除；避免高频全盘轮询。
- 仅恢复 XWeb 静态运行文件，保留微信自行生成的 `Profile`、Cookie、聊天记录及账号数据。
- 维护 `XWALKINFOS.xml` 核心版本信息，针对误变成 `-1` 等情形做有限修复。
- 从 v1.2.4 起，微信 `versionCode` 只用于诊断显示，不作为阻止恢复的白名单条件；**不代表未来所有 XWeb 版本都兼容本快照**。
- 不强制停止微信，不修改 FCM Token，不关闭 SELinux，也不依赖 LSPosed/Zygisk Hook。

## 安装与状态

在 Magisk 里安装 ZIP 并重启。通过模块的**操作**按钮查看 XWeb 内核、快照校验与最近成功恢复时间。保存位置：

```text
/data/adb/wechat_xweb_guard/core_1160289.tar
/data/adb/wechat_xweb_guard/core_1160289.sha256
/data/adb/wechat_xweb_guard/last_restore.txt
```

运行模块会动态更新 Magisk 中显示的“最近恢复时间”。启用前应确认微信为适配的 Google Play 版本以及 ARM64 环境。

## 隐私与注意事项

公开快照只包含 XWeb 静态内容，不包含 `Default`、`Cookies`、`History`、`MicroMsg` 或用户 Token。使用前仍请自行备份微信数据。系统或微信后续调整 XWeb ABI/文件格式时，应停止使用不匹配的快照。

禁用/卸载后重启停止自动守护，恢复行为不应该清除现有微信聊天数据。具体校验路径、已测试版本、恢复条件与授权声明见 [详细中文说明](docs/README_CN.md) 以及 [英文详细说明](docs/README_EN.md)。
