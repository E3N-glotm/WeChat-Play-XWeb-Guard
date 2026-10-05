# WeChat Play XWeb Guard

**Author / 作者：E3N**

WeChat Play XWeb Guard is a Magisk module for protecting and restoring the XWeb 1160289 runtime used by the validated Google Play build of WeChat.

WeChat Play XWeb Guard 是一个用于保护和恢复 **Google Play 版微信 XWeb 1160289** 的 Magisk 模块。

## v1.2.1 at a glance / v1.2.1 概览

- Bundles an authorized, privacy-scrubbed XWeb 1160289 static runtime snapshot directly in the Magisk ZIP.
- Works even when the user's current WeChat XWeb has already been deleted; no APKM is required.
- Uses BusyBox `inotifyd` for event-driven deletion detection instead of high-frequency polling.
- Restores only XWeb static runtime files and preserves WeChat-generated profile/dex state.
- Does not force-stop WeChat, modify FCM tokens, disable SELinux, or use LSPosed/Zygisk.
- WeChat build changes no longer automatically disable recovery. Unvalidated builds produce a warning, but recovery remains enabled by default.
- Optional `strict_build` mode is available for users who want recovery limited to the directly validated WeChat build.
- Stores the most recent successful recovery time in `/data/adb/wechat_xweb_guard/last_restore.txt`.
- Updates the Magisk module card description to `Last restore: YYYY-MM-DD HH:MM:SS ±ZZZZ`; before the first recovery it shows `Last restore: never`.

中文：

- Magisk ZIP **直接内置**经过脱敏检查的 XWeb 1160289 静态运行快照。
- 即使用户当前微信里的 XWeb 已经被清理掉，也能直接恢复；**不需要 APKM**。
- 使用 BusyBox `inotifyd` 事件监听，不做高频目录轮询。
- 只恢复 XWeb 静态运行文件，保留微信自己生成的 Profile 和 dex/oat 状态。
- 不强制停止微信、不修改 FCM token、不关闭 SELinux、不使用 LSPosed/Zygisk。
- 微信升级到其他 build 后，模块**不会自动停止恢复**；只提示当前 build 未验证，默认仍继续恢复 XWeb 1160289。
- 如果用户希望采用保守策略，可自行启用 `strict_build`。
- 每次完整恢复成功后记录最近一次恢复时间。
- Magisk 模块卡片会直接显示 `Last restore: YYYY-MM-DD HH:MM:SS ±ZZZZ`；从未恢复过时显示 `Last restore: never`。

## Validated reference / 已验证参考环境

| Item | Value |
|---|---|
| Package | `com.tencent.mm` |
| WeChat | Google Play 8.0.77 |
| versionCode | `3141` |
| XWeb | `1160289` |
| ABI | `arm64-v8a` |
| Root | Magisk-compatible |

The table above is the **directly tested reference**, not an automatic compatibility block. Starting with v1.2.0, a different WeChat versionCode is treated as **UNVALIDATED**, not **DISABLED**.

上表是**已实机验证的参考组合**，不是自动兼容性封锁条件。从 v1.2.0 开始，其他微信 versionCode 会被标记为 **UNVALIDATED**，但默认不会停止恢复。

Optional strict mode / 可选严格模式：

```sh
su -c 'touch /data/adb/wechat_xweb_guard/strict_build'
```

Return to default cross-build recovery / 恢复默认跨 build 恢复：

```sh
su -c 'rm -f /data/adb/wechat_xweb_guard/strict_build'
```

## Bundled XWeb snapshot / 内置 XWeb 快照

v1.2.1 includes:

```text
assets/core_1160289.tar
assets/core_1160289.sha256
```

Snapshot SHA256:

```text
09347ca1fb5b250fd79460b2b22083400046599fa5714af93124f2d1507f7619
```

The archive contains exactly the validated XWeb static runtime set:

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

It contains no `Default`, `Profile`, `Cookies`, `History`, `Login`, `MicroMsg`, FCM token, chat, or account data.

该快照只包含 XWeb 静态运行文件，不包含 `Default`、`Profile`、`Cookies`、`History`、`Login`、`MicroMsg`、FCM token、聊天记录或账号数据。

The maintainer **E3N states that they hold authorization to publicly redistribute the bundled XWeb binary files**. See [THIRD_PARTY_NOTICE.md](THIRD_PARTY_NOTICE.md).

维护者 **E3N 声明拥有这些 XWeb 二进制文件的公开再分发授权**。详细信息见 [THIRD_PARTY_NOTICE.md](THIRD_PARTY_NOTICE.md)。

## How it works / 工作原理

During installation:

1. The bundled snapshot SHA256 is verified.
2. The snapshot is moved into the private guard directory:

   ```text
   /data/adb/wechat_xweb_guard/core_1160289.tar
   /data/adb/wechat_xweb_guard/core_1160289.sha256
   ```

3. Only one persistent copy is kept after installation.
4. On boot, the guard watches the WeChat/XWeb paths using `inotifyd`.
5. If the XWeb static runtime disappears or becomes incomplete, the snapshot is verified again and restored.
6. Directory watches are automatically re-armed after recovery because restored directories have new inodes.
7. A successful recovery writes `last_restore.txt` and updates the installed `module.prop` description so Magisk can display the latest recovery time.

安装过程会先验证内置快照 SHA256，然后把快照移到独立私有目录，避免模块目录和保护目录各占一份空间。开机后通过 `inotifyd` 等待删除/移动事件；发现 XWeb 静态文件缺失后再次校验快照并恢复，同时重新订阅新目录 inode。

## Installation / 安装

Download the latest ZIP from:

https://github.com/E3N-glotm/WeChat-Play-XWeb-Guard/releases

在 Magisk 中选择 Release ZIP 安装并重启即可。v1.2.1 不要求用户事先准备 APKM，也不要求当前微信里已经存在 XWeb。

最近一次成功恢复时间保存在：

```text
/data/adb/wechat_xweb_guard/last_restore.txt
```

Magisk 模块卡片显示同一时间；模块不会为了立即刷新 UI 而强制结束 Magisk，重新进入或刷新模块页即可看到新值。

## Magisk Action / 模块操作

The Action entry reports:

- current WeChat versionCode;
- whether the build is validated or unvalidated;
- whether XWeb 1160289 is currently healthy;
- whether the protected snapshot verifies;
- watcher state;
- recent recovery log entries.
- last successful recovery timestamp.

Action 会显示当前微信版本、build 是否已验证、XWeb 状态、保护快照状态、watcher 状态、最近恢复日志和最近一次成功恢复时间。

## Uninstall / 卸载

Uninstall from Magisk and reboot.

The uninstaller removes:

```text
/data/adb/wechat_xweb_guard/
```

including the protected snapshot and guard state. It does **not** delete the XWeb runtime currently installed inside WeChat.

从 Magisk 卸载并重启即可。卸载会删除模块自己的保护快照、日志和状态，但**不会删除微信当前正在使用的 XWeb**。

## Documentation / 详细文档

- [中文详细说明](docs/README_CN.md)
- [Detailed English documentation](docs/README_EN.md)
- [Third-party binary notice / 第三方二进制声明](THIRD_PARTY_NOTICE.md)

## License / 许可

Guard source code: MIT License.

The bundled XWeb runtime is third-party software and is covered by the redistribution authorization stated by the repository maintainer. The MIT license applies to the guard source code, not to third-party XWeb binaries.

守护模块源码采用 MIT License。内置 XWeb 属于第三方二进制，其再分发依据维护者声明的授权；MIT License 仅适用于本项目守护代码，不自动覆盖第三方 XWeb 二进制。

This project is not affiliated with or endorsed by Tencent, WeChat, Google, or Xiaomi.

本项目与腾讯、微信、Google、小米无隶属或官方背书关系。
