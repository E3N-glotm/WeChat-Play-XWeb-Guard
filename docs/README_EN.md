# WeChat Play XWeb Guard — Detailed English Documentation

**Author: E3N**  
**Module ID: `wechat_xweb_guard`**  
**Version: v1.2.2**

## 1. Purpose

Some Google Play builds of WeChat use a separate XWeb/Pinus runtime stored in WeChat's private application data. Aggressive root cleanup workflows can mistakenly remove this relatively large runtime.

On the validated device, removal of XWeb 1160289 caused:

- XWeb 1160289 no longer being selected;
- Mini Programs/web pages showing an “upgrading” state again;
- `app_xweb_data/xweb_1160289` becoming missing or incomplete;
- temporary fallback to the system WebView;
- the need to reinstall XWeb even though the WeChat APK itself had not changed.

This module has a narrow purpose: **keep a verified XWeb 1160289 static runtime snapshot and restore it after accidental deletion.**

## 2. What changed in v1.2.0

v1.2.0 introduces two policy changes:

1. The Release ZIP **directly bundles the authorized XWeb 1160289 static runtime snapshot**.
2. A WeChat versionCode change **no longer automatically disables recovery**.

As a result, a new user can install v1.2.0 and recover XWeb 1160289 even if the current WeChat XWeb directory is already empty. No APKM is required.

## 3. Validated reference environment

| Item | Validated value |
|---|---|
| Package | `com.tencent.mm` |
| WeChat | Google Play 8.0.77 |
| versionCode | `3141` |
| XWeb | `1160289` |
| ABI | `arm64-v8a` |
| Root | Magisk-compatible |

versionCode 3141 is a **directly tested reference**, not a default recovery block.

On a different WeChat versionCode, v1.2.0:

- reports the build as unvalidated;
- continues protecting/restoring XWeb 1160289 by default;
- does not downgrade WeChat;
- leaves compatibility judgment to the user.

Optional strict mode:

```sh
su -c 'touch /data/adb/wechat_xweb_guard/strict_build'
```

With strict mode enabled, automatic recovery is limited to versionCode 3141.

Return to the default cross-build policy:

```sh
su -c 'rm -f /data/adb/wechat_xweb_guard/strict_build'
```

## 4. Bundled snapshot and privacy scrub

The Release ZIP includes:

```text
assets/core_1160289.tar
assets/core_1160289.sha256
```

Snapshot SHA256:

```text
09347ca1fb5b250fd79460b2b22083400046599fa5714af93124f2d1507f7619
```

The archive contains exactly ten static XWeb entries:

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

It contains no:

- `Default`;
- `Profile`;
- `Cookies`;
- `History`;
- `Login`;
- `MicroMsg`;
- FCM credentials;
- chat data;
- account records.

“Privacy scrubbed” here means the distributed archive contains no user-data/profile paths. The XWeb binaries themselves are not modified for “scrubbing.”

The maintainer **E3N states that they hold authorization to publicly redistribute these XWeb binary files**.

## 5. Installation behavior

`customize.sh`:

1. requires `arm64-v8a`;
2. creates `/data/adb/wechat_xweb_guard/`;
3. reads the bundled snapshot checksum;
4. calculates the SHA256 of the bundled tar;
5. aborts if the checksum differs;
6. moves the verified snapshot into the private guard directory;
7. verifies the moved copy again;
8. keeps only one persistent copy after installation.

The protected files are:

```text
/data/adb/wechat_xweb_guard/core_1160289.tar
/data/adb/wechat_xweb_guard/core_1160289.sha256
```

## 6. Event-driven watcher

`watch.sh` launches BusyBox `inotifyd`.

Watched paths include:

```text
.../com.tencent.mm/
.../com.tencent.mm/app_xweb_data/
.../xweb_1160289/
.../xweb_1160289/extracted_xwalkcore/
.../xweb_1160289/apk/
.../xweb_1160289/zip/
```

The healthy-state design does not scan the XWeb tree every second. `inotifyd` normally sleeps in the kernel until a relevant file-system event occurs.

When a protected file/directory is deleted or moved, `event.sh` invokes `repair.sh`.

Recovered directories receive new inodes, so the event handler terminates only its parent `inotifyd`; the outer watcher then subscribes to the replacement paths.

## 7. Automatic recovery conditions

In the default policy, recovery requires:

1. WeChat application data still exists;
2. `MicroMsg` exists, preventing reconstruction after an intentional full app-data clear;
3. XWeb 1160289 static runtime is missing or incomplete;
4. the protected snapshot exists;
5. the snapshot SHA256 verifies;
6. if `strict_build` is enabled, WeChat versionCode must be 3141.

There is no default build-number block in v1.2.0.

## 8. Files restored

Only the static runtime whitelist is restored:

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

The guard does not overwrite:

- WebView `Default` profile data;
- cookies/history;
- dex/oat runtime state;
- chats;
- FCM identity;
- account information.

WeChat is not force-stopped as part of recovery.

## 9. XWeb selection preference

If the static runtime has been restored but WeChat previously cleared the selection preference, the guard may restore:

```xml
<boolean name="using_core_version_1160289" value="true" />
```

On an unvalidated WeChat build, the action is explicitly logged as a warning.

## 10. Installation

Download:

```text
WeChat-Play-XWeb-Guard-v1.2.1.zip
```

from GitHub Releases and install it from Magisk.

Successful installation should report:

```text
Bundled XWeb 1160289 snapshot verified and installed.
```

No APKM is required.

## 11. Magisk Action

The Action entry reports:

- current WeChat versionCode;
- validated/unvalidated build state;
- whether unvalidated-build recovery is allowed;
- live XWeb health;
- protected snapshot verification;
- watcher PID/state;
- recent recovery log entries.

## 12. Diagnostics

Guard log:

```sh
su -c 'cat /data/adb/wechat_xweb_guard/guard.log'
```

Snapshot verification:

```sh
su -c 'cd /data/adb/wechat_xweb_guard && /data/adb/magisk/busybox sha256sum -c core_1160289.sha256'
```

Watcher:

```sh
su -c 'cat /data/adb/wechat_xweb_guard/watcher.pid'
```

WeChat build:

```sh
su -c "dumpsys package com.tencent.mm | grep -E 'versionCode=|versionName='"
```

XWeb preference:

```sh
su -c 'cat /data_mirror/data_ce/null/0/com.tencent.mm/shared_prefs/xweb_using_core_version.xml'
```

## 13. Battery impact

The guard is event driven, not a high-frequency scanner.

BusyBox `inotifyd` normally blocks in the kernel. The outer watcher briefly sleeps/re-arms only when:

- credential-encrypted data is not yet available after boot;
- a restored directory has a new inode;
- `inotifyd` exits and watches must be rebuilt.

## 14. Why not chmod/chattr

`chmod` does not reliably protect files from root cleanup tools and may interfere with WeChat's own access.

`chattr +i` can block legitimate XWeb replacement/upgrades and can still be removed by root software.

The module therefore allows WeChat to manage its directory normally and restores the runtime only after deletion.

## 15. WeChat upgrades

Default v1.2.0 behavior:

- versionCode changes: XWeb 1160289 recovery continues;
- Action/log output: UNVALIDATED warning;
- if the user confirms it works: no action required;
- if incompatible: disable/uninstall the module or enable `strict_build`.

The module does not make the compatibility decision for the user.

## Last successful recovery timestamp

Starting with v1.2.1, every fully successful `repair.sh` run writes:

```text
/data/adb/wechat_xweb_guard/last_restore.txt
```

Timestamp format:

```text
YYYY-MM-DD HH:MM:SS ±ZZZZ
```

Example:

```text
2026-10-05 12:11:16 +0800
```

The module also rewrites the installed `module.prop` description:

```text
description=XWeb 1160289 guard | Last restore: 2026-10-05 12:11:16 +0800
```

Magisk therefore shows the same value on the module card after the module list is refreshed or reopened.

Before the first successful recovery:

```text
Last restore: never
```

Module upgrades preserve `last_restore.txt`. The guard does not force-stop Magisk merely to refresh the UI.

## 16. Uninstall

Uninstall from Magisk and reboot.

The uninstaller stops the watcher and deletes:

```text
/data/adb/wechat_xweb_guard/
```

including the protected snapshot, checksum, log, and runtime state.

It does **not** remove the XWeb runtime currently installed inside WeChat.

## 17. Validation history

Development validation includes:

- single protected-file removal → automatic recovery;
- whole `zip` subdirectory removal → automatic recovery;
- watcher re-arm after reconstructed directories;
- XWeb internal file checksum validation;
- actual `libxwebcore.so` mapping in a WeChat process;
- unchanged FCM identity during XWeb repair;
- no user profile/chat paths in the bundled tar;
- release-time SHA256 and archive path checks.

## 18. License and third-party notice

The guard source code is MIT licensed.

Bundled XWeb 1160289 is third-party software. The maintainer **E3N states that they hold authorization to publicly redistribute these XWeb binary files**.

The MIT license applies to the guard source code and does not alter ownership/licensing of the bundled third-party XWeb runtime.

This project is not affiliated with or endorsed by Tencent, WeChat, Google, or Xiaomi.
