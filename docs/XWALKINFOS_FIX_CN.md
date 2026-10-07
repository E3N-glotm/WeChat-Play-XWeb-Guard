# v1.2.2：XWALKINFOS 元数据守护

## 问题现象

实机在 2026-10-07 再次出现微信“正在升级”。检查发现：

- XWeb 1160289 的静态运行文件已经被 Guard 完整恢复；
- `libxwebcore.so`、`base.apk`、`base.zip` 大小均正确；
- 但 `xweb_using_core_version.xml` 是空 `<map />`；
- 新启动的微信/AppBrand 仍使用 System WebView。

这说明 v1.2.1 以前只恢复静态文件还不完整。

## 根因

反查 Google Play 微信 8.0.77（versionCode 3141）的 XWeb 初始化逻辑后确认：

`xweb_using_core_version.xml` 不是权威核心来源。微信主进程初始化时会主动清空该文件，然后从：

```text
shared_prefs/XWALKINFOS.xml
```

重新读取当前 ABI 对应的 XWeb core version。

arm64-v8a 的关键字段是：

```text
back_core_version_for_arm64-v8a
```

故障现场该值为：

```xml
<int name="back_core_version_for_arm64-v8a" value="-1" />
```

因此，即使 1160289 文件已经恢复，微信仍认为没有可用 XWeb 核心，随后继续走 System WebView/“正在升级”流程。

## 验证

仅把该字段恢复为：

```xml
<int name="back_core_version_for_arm64-v8a" value="1160289" />
```

不强制写 `xweb_using_core_version.xml`，重新启动微信后，微信自己生成：

```xml
<boolean name="using_core_version_1160289" value="true" />
```

随后新启动的 `com.tencent.mm:appbrand0` 实际映射：

```text
app_xweb_data/xweb_1160289/extracted_xwalkcore/libxwebcore.so
```

说明 Pinus/XWeb 1160289 已真正重新启用。

## v1.2.2 的修复

v1.2.2 将 `XWALKINFOS.xml` 纳入守护范围：

1. 恢复 XWeb 静态文件后，同步确保 `back_core_version_for_arm64-v8a=1160289`。
2. 即使静态文件完全健康，只要 metadata 被改成 `-1`，也会进行 metadata-only 修复。
3. 使用 BusyBox `inotifyd` 监听 `XWALKINFOS.xml` 的写入、关闭写入、删除、移动和 inode 失效事件。
4. 如果 metadata 文件被整体替换，watcher 会重新订阅新的 inode。
5. metadata-only 修复不会重写约 240 MB 的 XWeb 静态文件。
6. metadata 修复同样更新 Magisk 的最近一次恢复时间。

## 实机 metadata-only 测试

在 XWeb 1160289 静态文件健康的情况下，人工把：

```text
back_core_version_for_arm64-v8a
```

改成 `-1`。

约 6 秒内 Guard 自动恢复为 `1160289`，同时：

- `libxwebcore.so` mtime 未变化，说明没有重写大文件；
- watcher 保持运行；
- Magisk description 的 Last restore 时间同步更新；
- 日志记录 `RESTORED: XWALKINFOS core metadata 1160289`。

这使 v1.2.2 能同时防护“XWeb 文件被删”和“核心版本元数据被清空”两类问题。
