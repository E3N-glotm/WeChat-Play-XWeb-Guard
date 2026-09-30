# WeChat Play XWeb Guard

**Author / 作者：E3N**

A small Magisk module that protects the locally installed XWeb runtime used by the Google Play build of WeChat from accidental cleanup, and restores the verified static runtime files when they disappear.

一个用于保护 **Google Play 版微信 XWeb 内核**的 Magisk 模块：在本机生成受保护快照，通过文件事件监听检测误删，并在兼容条件满足时自动恢复 XWeb 静态运行文件。

> **This repository does not contain or redistribute WeChat or XWeb binaries.**  
> **本仓库不包含、也不重新分发微信或 XWeb 二进制文件。**

## Documentation / 文档

- [中文详细说明](docs/README_CN.md)
- [Detailed English documentation](docs/README_EN.md)

## Current validated target / 当前验证目标

| Item | Validated value |
|---|---|
| Package | `com.tencent.mm` |
| WeChat | Google Play 8.0.77 |
| versionCode | `3141` |
| XWeb | `1160289` |
| ABI | `arm64-v8a` |
| Root environment | Magisk-compatible |

The compatibility checks are intentionally strict. If WeChat is upgraded to a different build, the module does **not** force the old XWeb into it.

兼容性检查采用保守策略。微信升级到其他 build 后，模块会停止旧版本自动恢复，而不是强行把 XWeb 1160289 写入未知版本。

## Core behavior / 核心行为

1. During installation, the module looks for an already healthy local XWeb 1160289.
2. If found, it creates a private snapshot under `/data/adb/wechat_xweb_guard/`.
3. A BusyBox `inotifyd` watcher sleeps until a relevant XWeb path is deleted or moved.
4. If the static runtime becomes incomplete, the module verifies the private snapshot and restores only the protected static files.
5. WeChat-generated WebView profile data is preserved; WeChat is not force-stopped.

安装时从用户设备当前健康的 XWeb 1160289 **本地生成**保护快照；运行时使用 `inotifyd` 监听删除/移动事件。发生误删后仅恢复静态运行文件，不备份聊天、账号、Cookie、历史记录或 WebView Profile，也不会为了恢复而强制停止微信。

## Install / 安装

Download the ZIP from [Releases](../../releases), install it in Magisk, then reboot.

从 [Releases](../../releases) 下载 ZIP，在 Magisk 中安装并重启。

If the compatible XWeb core is healthy at installation time, the local snapshot is created immediately. Otherwise the module remains passive and will bootstrap a snapshot later when a healthy compatible XWeb appears.

如果安装时本机已有健康且兼容的 XWeb，快照会立即建立；否则模块保持被动，不会伪造核心。之后微信重新生成健康 XWeb 时，模块会再尝试建立本地快照。

## Privacy / 隐私

The snapshot whitelist contains only:

- `apk/base.apk`
- `zip/base.zip`
- XWeb static runtime libraries/configuration under `extracted_xwalkcore`

The module explicitly rejects snapshot content containing profile/chat-style paths such as `Default`, `Profile`, `Cookies`, `History`, `Login`, or `MicroMsg`.

保护快照只包含 XWeb 静态运行文件，并显式拒绝包含 `Default`、`Profile`、`Cookies`、`History`、`Login`、`MicroMsg` 等个人数据路径。

## License

Module source code: MIT License.

WeChat and XWeb are third-party software. This project is not affiliated with or endorsed by Tencent, WeChat, Google, or Xiaomi.

模块源码采用 MIT License。微信与 XWeb 属于第三方软件；本项目与腾讯、微信、Google、小米无隶属或官方背书关系。
