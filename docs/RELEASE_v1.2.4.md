# WeChat Play XWeb Guard v1.2.4

Author / 作者: **E3N**

## 中文

v1.2.4 解决两个实际问题：

1. **彻底去除微信版本/build 限制。**
2. **修复恢复脚本中的错误 `+` 标记。**

### 微信版本不再参与恢复判定

本版本删除了 `EXPECTED_VERSION_CODE`、`validated_wechat`、`strict_build` 和 `recovery_allowed`。

微信 `versionCode` 只用于 Magisk Action 诊断显示，不再影响：

- XWeb 快照生成；
- XWeb 1160289 自动恢复；
- XWALKINFOS 元数据修复；
- 安装或运行资格。

本次已在 Google Play 微信 **8.0.79 / versionCode 3182** 上完成实机验证。

### 修复 `ERROR: could not restore +`

旧脚本中的恢复文件循环被错误写入了 `+` 标记，清理发生后会尝试恢复一个名为 `+` 的不存在文件，并反复出现：

```text
ERROR: could not restore +
```

v1.2.4 已恢复正确的静态文件白名单循环，并同时修复两个 XML 生成分支中的同类错误 `+` 标记。

### 8.0.79 / 3182 实机结果

- XWeb 1160289 三个关键大文件恢复成功；
- `XWALKINFOS.xml` 恢复为 `back_core_version_for_arm64-v8a=1160289`；
- 微信重启后自行写入 `first_using_core_version_1160289` 和 `using_core_version_1160289=true`；
- `com.tencent.mm:appbrand0` 实际映射加载 `xweb_1160289/extracted_xwalkcore/libxwebcore.so`；
- watcher 正常运行。

## English

v1.2.4 addresses two concrete issues:

1. **All WeChat version/build gating has been removed.**
2. **Malformed `+` tokens in the recovery scripts have been fixed.**

WeChat `versionCode` is diagnostic information only. It no longer affects snapshot creation, XWeb 1160289 recovery, XWALKINFOS repair, installation, or runtime eligibility.

The previous malformed restore loop could attempt to copy a non-existent file named `+`, producing:

```text
ERROR: could not restore +
```

The static runtime whitelist and XML generation paths are corrected in v1.2.4.

Device validation was completed on Google Play WeChat **8.0.79 / versionCode 3182**. After repair and WeChat restart, `com.tencent.mm:appbrand0` mapped the restored XWeb 1160289 `libxwebcore.so`.
