# WeChat Play XWeb Guard — Detailed English Documentation

**Author: E3N**  
**Module ID: `wechat_xweb_guard`**  
**Current public release: v1.1.0**

## 1. Purpose

Some Google Play builds of WeChat use a separate XWeb/Pinus runtime stored in WeChat's private application data. Because the runtime is relatively large, aggressive cleanup workflows can incorrectly treat it as disposable cache data.

On the validated device, removal of XWeb 1160289 caused symptoms such as:

- WeChat no longer reporting XWeb 1160289 as the active core;
- Mini Programs or web pages showing an “upgrading” state again;
- `app_xweb_data/xweb_1160289` becoming missing or incomplete;
- temporary fallback to the system WebView;
- the need to reinstall XWeb even though the WeChat application version itself had not changed.

WeChat Play XWeb Guard has one intentionally narrow goal:

> Protect an already healthy, locally installed XWeb runtime from accidental deletion and restore its verified static runtime files when required.

It is **not** a WeChat patcher, XWeb downloader, downgrade utility, FCM module, or LSPosed/Zygisk hook.

## 2. Validated compatibility

The current automatic recovery policy is locked to:

| Item | Validated value |
|---|---|
| Package | `com.tencent.mm` |
| WeChat | Google Play 8.0.77 |
| versionCode | `3141` |
| XWeb | `1160289` |
| ABI | `arm64-v8a` |
| Root environment | Magisk-compatible |

This strict check is deliberate. If WeChat is upgraded and the versionCode changes, the guard will **not** inject XWeb 1160289 into the unknown build.

## 3. Why the release does not bundle the 240 MB XWeb snapshot

The original private prototype stored a local XWeb snapshot directly inside the module directory. That snapshot was approximately 240 MB.

Public v1.1.0 changes the model to:

> **Publish the guard code; generate the XWeb snapshot locally from the user's own healthy installation.**

The GitHub source tree and Release ZIP do not contain:

- `libxwebcore.so`;
- XWeb `base.zip`;
- XWeb `base.apk`;
- WeChat APK files;
- chat data;
- account data.

When a healthy compatible runtime exists, the module creates:

```text
/data/adb/wechat_xweb_guard/core_1160289.tar
/data/adb/wechat_xweb_guard/core_1160289.sha256
```

These files are generated locally on the rooted device and are not part of the public distribution.

## 4. Architecture

### 4.1 Installation

`customize.sh`:

1. requires `arm64-v8a`;
2. creates `/data/adb/wechat_xweb_guard`;
3. can migrate a verified snapshot from the earlier private prototype;
4. verifies WeChat versionCode 3141;
5. checks the local XWeb 1160289 structure;
6. creates a whitelist-only local archive;
7. records a SHA256 checksum.

If XWeb is already missing at install time, the module does not fabricate a core. It remains passive until a healthy compatible core later becomes available.

### 4.2 Health criteria

The current target is validated using the following static file sizes:

```text
extracted_xwalkcore/libxwebcore.so = 135166832 bytes
apk/base.apk                       =  33171682 bytes
zip/base.zip                       =  70436321 bytes
```

The module also requires:

```text
extracted_xwalkcore/filelist.config
extracted_xwalkcore/dummy.dat
```

These are version-specific guards, not a generic XWeb detector.

### 4.3 Event-driven watcher

`watch.sh` launches BusyBox `inotifyd` and normally sleeps in the kernel until a relevant file or directory is removed/moved.

Watched paths include:

```text
.../com.tencent.mm/
.../com.tencent.mm/app_xweb_data/
.../xweb_1160289/
.../xweb_1160289/extracted_xwalkcore/
.../xweb_1160289/apk/
.../xweb_1160289/zip/
```

When a watched runtime path disappears, `event.sh` invokes `repair.sh`.

Recovered directories receive new inodes, so the event handler terminates only its parent `inotifyd`; the outer watcher then re-arms watches against the replacement directories.

## 5. Recovery policy

Automatic recovery requires all of the following:

1. WeChat application data still exists;
2. the `MicroMsg` directory exists, preventing reconstruction after an intentional full data clear;
3. WeChat versionCode is still 3141;
4. the XWeb runtime is missing or incomplete;
5. the private local snapshot exists;
6. the snapshot SHA256 verifies successfully.

Recovery does **not**:

- force-stop WeChat;
- clear chats;
- change FCM tokens;
- change global Android properties;
- disable SELinux;
- install LSPosed/Zygisk hooks;
- overwrite the WebView `Default` profile;
- overwrite dex/oat state.

Only whitelisted static XWeb runtime files are restored.

If WeChat has cleared the XWeb selection preference after the files disappeared, the guard may restore:

```xml
<boolean name="using_core_version_1160289" value="true" />
```

This happens only under the versionCode 3141 + verified local snapshot policy.

## 6. Privacy model

The snapshot is created with an explicit whitelist rather than archiving the full XWeb directory.

Allowed files:

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

The snapshot is rejected if its path list contains profile/private-data names such as:

```text
Default
Profile
Cookies
History
Login
MicroMsg
```

The snapshot is therefore an XWeb runtime recovery artifact, not a WeChat/account backup.

## 7. Installation

1. Download `WeChat-Play-XWeb-Guard-v1.1.0.zip` from GitHub Releases.
2. Install it from Magisk.
3. Review the installer output:
   - `Local XWeb 1160289 snapshot is ready` means protection is active;
   - otherwise the module stays passive until it sees a healthy compatible XWeb.
4. Reboot.

## 8. Magisk Action

The module exposes an Action diagnostics entry that reports:

- current WeChat versionCode;
- whether live XWeb 1160289 is healthy;
- whether the protected local snapshot is valid;
- watcher PID/running state;
- recent guard log entries.

If the live core is healthy but the snapshot is missing, Action attempts to bootstrap it.

If the live core is missing and the snapshot is valid, Action performs a repair check.

## 9. Diagnostics

Log:

```sh
su -c 'cat /data/adb/wechat_xweb_guard/guard.log'
```

Snapshot integrity:

```sh
su -c 'cd /data/adb/wechat_xweb_guard && /data/adb/magisk/busybox sha256sum -c core_1160289.sha256'
```

Watcher:

```sh
su -c 'cat /data/adb/wechat_xweb_guard/watcher.pid'
```

WeChat version:

```sh
su -c "dumpsys package com.tencent.mm | grep -E 'versionCode=|versionName='"
```

XWeb selection preference:

```sh
su -c 'cat /data_mirror/data_ce/null/0/com.tencent.mm/shared_prefs/xweb_using_core_version.xml'
```

## 10. Battery impact

The healthy-state design is event driven. BusyBox `inotifyd` blocks until a filesystem event occurs instead of scanning the XWeb directory every second.

The outer watcher uses short sleeps only when credential-encrypted app data is not yet available after boot, or when an inotify watch must be re-armed after directory replacement.

## 11. Uninstall

Uninstall the module from Magisk and reboot.

`uninstall.sh` removes:

```text
/data/adb/wechat_xweb_guard/
```

including the local snapshot, checksum, log, and watcher state.

It does **not** remove the XWeb runtime currently installed inside WeChat.

## 12. WeChat upgrades

When WeChat changes to a different versionCode:

- the old XWeb snapshot is not automatically restored;
- WeChat is not downgraded;
- the new WeChat XWeb state is not overwritten;
- the old private snapshot remains until module uninstall or a future module release explicitly supports the new version.

This is intentionally safer than making the XWeb directory immutable.

## 13. Why not chmod or chattr +i

`chmod` cannot reliably stop a root cleanup tool from deleting the directory, while overly restrictive permissions can interfere with WeChat itself.

`chattr +i` is stronger, but can block legitimate XWeb replacement/upgrades and can still be cleared by root software.

The module instead allows WeChat to manage its own runtime normally and provides recovery only after accidental deletion.

## 14. Validation history

The private prototype was tested with:

- single protected-file deletion;
- whole XWeb subdirectory removal;
- watcher re-arm after directory reconstruction;
- repeated real cleanup-triggered recovery events.

Public v1.1.0 keeps that event/repair model, but moves the protected XWeb snapshot out of the release and generates it locally.

## 15. Limitations and risk

- Any root module can affect system stability; keep a working Magisk recovery path.
- The current compatibility target is intentionally narrow.
- WeChat's private directory layout is undocumented and may change.
- The module will not reconstruct WeChat after an intentional full application-data clear.
- A damaged snapshot fails closed when SHA256 verification fails.
- The module is not a replacement for WeChat's own XWeb installer/updater.

## 16. License and third-party notice

The module source code is MIT licensed.

WeChat, XWeb, and their binaries belong to their respective rights holders. This repository contains no WeChat/XWeb binaries and provides no third-party XWeb download.

This project is not affiliated with or endorsed by Tencent, WeChat, Google, or Xiaomi.
