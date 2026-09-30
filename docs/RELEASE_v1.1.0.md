# WeChat Play XWeb Guard v1.1.0

Author / 作者: **E3N**

## 中文

首个公开版本。用于保护 Google Play 版微信 8.0.77（versionCode 3141）使用的 XWeb 1160289，防止 XWeb 静态运行文件被清理工具误删后反复出现“正在升级”或回退系统 WebView。

### 主要功能

- 安装时从用户设备上**已有且健康的 XWeb 1160289 本地生成保护快照**。
- 使用 BusyBox `inotifyd` 事件监听，不做高频目录轮询。
- 检测关键 XWeb 文件/目录被删除或移动后，从本机验证快照恢复。
- 恢复后自动重新订阅新目录 inode。
- 不强制停止微信，不修改 FCM token，不关闭 SELinux，不使用 LSPosed/Zygisk。
- 保留 WeChat 生成的 WebView Profile 与 dex/oat 状态。
- 微信 versionCode 不是 3141 时拒绝把旧 XWeb 强行恢复进去。
- 主动清除整个微信应用数据后不会尝试重建微信数据。

### 隐私与分发

公开 ZIP **不包含微信或 XWeb 二进制文件**。仓库不包含 `libxwebcore.so`、XWeb `base.apk`、`base.zip` 或微信 APK。

本地快照仅白名单保存 XWeb 静态运行文件，并拒绝包含 `Default`、`Profile`、`Cookies`、`History`、`Login`、`MicroMsg` 等路径。

### 已验证环境

- `com.tencent.mm`
- Google Play WeChat 8.0.77
- versionCode `3141`
- XWeb `1160289`
- `arm64-v8a`
- Magisk-compatible root environment

## English

First public release. It protects the locally installed XWeb 1160289 runtime used by the validated Google Play WeChat 8.0.77 (versionCode 3141) build from accidental cleanup.

### Highlights

- Creates the protected snapshot **locally from the user's own healthy XWeb installation**.
- Uses BusyBox `inotifyd` for event-driven monitoring instead of high-frequency polling.
- Restores only verified static XWeb runtime files after deletion/move events.
- Re-arms watches after recovered directories receive new inodes.
- Does not force-stop WeChat, modify FCM tokens, disable SELinux, or use LSPosed/Zygisk.
- Preserves WeChat-generated WebView profiles and dex/oat state.
- Refuses recovery when WeChat versionCode is no longer 3141.
- Does not reconstruct WeChat after an intentional full app-data clear.

### Privacy / distribution

The public ZIP contains **no WeChat or XWeb binaries**. It does not ship `libxwebcore.so`, XWeb `base.apk`, `base.zip`, or any WeChat APK.

The locally generated snapshot uses a strict static-file whitelist and rejects profile/private-data path names.

## Verification

GitHub Actions: **36657161884 — passed**

Release ZIP SHA256:

```text
1b9b90c2406b33e0c200559b021dd672260a5739e3f3ce83208c1ae8647e69d1
```

See the repository README and `docs/README_CN.md` / `docs/README_EN.md` for full documentation.
