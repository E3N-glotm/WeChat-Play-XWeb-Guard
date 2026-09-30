# WeChat Play XWeb Guard v1.2.0

Author / 作者: **E3N**

## 中文

v1.2.0 改为直接在 Magisk Release ZIP 中内置经过脱敏检查的 XWeb 1160289 静态运行快照。

其他用户安装后即使当前微信的 XWeb 已经被清理，也可以直接恢复，不需要 APKM。

### 主要变化

- 内置 XWeb 1160289 静态快照。
- 快照 SHA256：`09347ca1fb5b250fd79460b2b22083400046599fa5714af93124f2d1507f7619`。
- 构建/Release 测试会再次检查 SHA256。
- 构建/Release 测试会检查 tar 路径，不允许出现 `Default/Profile/Cookies/History/Login/MicroMsg` 等用户数据路径。
- 微信 versionCode 变化后默认继续恢复 1160289，只记录 UNVALIDATED 警告。
- 新增可选 `strict_build` 模式，由用户决定是否只允许已验证 build。
- 安装后把内置快照移动到 `/data/adb/wechat_xweb_guard/`，避免长期保存两份 240 MB 文件。
- 不强制停止微信，不修改 FCM token，不使用 LSPosed/Zygisk。

维护者 E3N 声明拥有内置 XWeb 二进制的公开再分发授权。

## English

v1.2.0 directly bundles the privacy-scrubbed XWeb 1160289 static runtime snapshot in the Magisk Release ZIP.

Users can therefore recover XWeb even when the current WeChat XWeb directory is already missing. No APKM is required.

### Highlights

- Bundled XWeb 1160289 static runtime snapshot.
- Snapshot SHA256: `09347ca1fb5b250fd79460b2b22083400046599fa5714af93124f2d1507f7619`.
- Build/release tests verify the snapshot SHA256.
- Build/release tests reject tar paths containing `Default/Profile/Cookies/History/Login/MicroMsg`.
- Recovery continues by default after a WeChat versionCode change, with an UNVALIDATED warning.
- Optional `strict_build` mode lets the user restrict recovery to the directly validated build.
- The bundled archive is moved to `/data/adb/wechat_xweb_guard/` during installation so two persistent 240 MB copies are not kept.
- No forced WeChat stop, FCM token modification, LSPosed, or Zygisk.

The maintainer E3N states that they hold authorization to publicly redistribute the bundled XWeb binaries.
