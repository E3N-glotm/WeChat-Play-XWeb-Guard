# WeChat Play XWeb Guard v1.2.2

Author / 作者: **E3N**

## 中文

v1.2.2 修复“XWeb 文件已经恢复，但微信仍显示正在升级”的根因。

实机确认微信主进程会从 `XWALKINFOS.xml` 的 `back_core_version_for_arm64-v8a` 重新确定当前 XWeb core。故障时该值被重置为 `-1`，导致 1160289 文件虽然完整，微信仍继续使用 System WebView。

本版本：

- 恢复静态 XWeb 后同步恢复 `XWALKINFOS` core version；
- metadata 为 `-1` 而核心文件健康时，只修 metadata，不重写 240 MB 文件；
- 使用 `inotifyd` 监听 `XWALKINFOS.xml` 的修改、删除、移动和替换；
- metadata 修复同样更新 Magisk 最近恢复时间；
- 保持跨微信 build 默认继续恢复策略；
- 继续内置已授权的 XWeb 1160289 静态快照。

实机 metadata-only 测试中，将值改成 `-1` 后约 6 秒自动恢复为 `1160289`，静态核心文件 mtime 不变，watcher 保持运行。

## English

v1.2.2 fixes the root cause of the “XWeb files restored but WeChat still upgrading” failure.

Device forensics confirmed that WeChat main process determines the current XWeb core from `back_core_version_for_arm64-v8a` in `XWALKINFOS.xml`. The failing device had this value reset to `-1`, so WeChat continued to use System WebView despite a complete XWeb 1160289 runtime.

This release:

- restores XWALKINFOS core-version metadata with the static runtime;
- repairs metadata-only damage without rewriting the 240 MB runtime;
- watches XWALKINFOS modification/deletion/move/replacement events with `inotifyd`;
- updates the Magisk last-restore timestamp on metadata recovery;
- keeps cross-build recovery enabled by default;
- continues to bundle the authorized XWeb 1160289 static snapshot.

In a metadata-only device test, changing the value to `-1` was automatically repaired to `1160289` in roughly six seconds while static core mtimes remained unchanged and the watcher stayed alive.
