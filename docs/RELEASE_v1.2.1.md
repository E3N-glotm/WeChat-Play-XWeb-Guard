# WeChat Play XWeb Guard v1.2.1

Author / 作者: **E3N**

## 中文

v1.2.1 在 v1.2.0 已有的“内置 XWeb 1160289 + 跨微信 build 默认继续恢复”基础上，新增**最近一次成功恢复时间戳**。

### 新增

- 每次完整恢复成功后写入：

  ```text
  /data/adb/wechat_xweb_guard/last_restore.txt
  ```

- 时间格式：`YYYY-MM-DD HH:MM:SS ±ZZZZ`。
- 自动更新已安装模块的 `module.prop` description，使 Magisk 模块卡片显示最近一次恢复时间。
- 尚未发生恢复时显示 `Last restore: never`。
- Magisk Action 同步显示最近一次成功恢复时间。
- 模块升级保留历史时间戳。
- 不为了刷新 UI 强制停止 Magisk；重新进入/刷新模块页即可读取更新后的 description。

### 实机验证

2026-10-05 在当前设备上进行一次受控恢复测试：

```text
Before: 2026-10-05 12:01:10 +0800
After:  2026-10-05 12:11:16 +0800
```

恢复后的 `dummy.dat` 与测试前文件 MD5 一致，watcher 保持运行，Magisk description 同步更新。

## English

v1.2.1 adds a **persistent last-successful-recovery timestamp** on top of v1.2.0's bundled XWeb 1160289 and cross-build recovery policy.

### New

- Successful repairs write `/data/adb/wechat_xweb_guard/last_restore.txt`.
- Timestamp format: `YYYY-MM-DD HH:MM:SS ±ZZZZ`.
- The installed `module.prop` description is updated so Magisk can display the latest recovery time directly on the module card.
- Before the first successful recovery it shows `Last restore: never`.
- Magisk Action reports the same timestamp.
- Module upgrades preserve the timestamp.
- Magisk is not force-stopped just to refresh the UI.

### Device validation

A controlled recovery test on 2026-10-05 updated the timestamp from:

```text
2026-10-05 12:01:10 +0800
```

to:

```text
2026-10-05 12:11:16 +0800
```

The restored `dummy.dat` matched the pre-test MD5, the watcher remained alive, and the Magisk description updated to the same timestamp.
