# v1.2.2: XWALKINFOS Metadata Guard

## Symptom

On 2026-10-07 the validated device showed WeChat's “upgrading” state again even though XWeb Guard had already restored the XWeb 1160289 static runtime.

Inspection showed:

- `libxwebcore.so`, `base.apk`, and `base.zip` were present with the expected sizes;
- `xweb_using_core_version.xml` was an empty `<map />`;
- newly started WeChat/AppBrand components continued to use System WebView.

This proved that restoring only the static runtime was insufficient.

## Root cause

Reverse inspection of Google Play WeChat 8.0.77 (versionCode 3141) showed that `xweb_using_core_version.xml` is derived state, not the authoritative current-core source.

During main-process initialization WeChat clears that preference and reads the current ABI-specific core version from:

```text
shared_prefs/XWALKINFOS.xml
```

For arm64-v8a the relevant key is:

```text
back_core_version_for_arm64-v8a
```

The failing device contained:

```xml
<int name="back_core_version_for_arm64-v8a" value="-1" />
```

Therefore WeChat considered the restored XWeb runtime unavailable and continued with System WebView.

## Proof

Changing only that field to:

```xml
<int name="back_core_version_for_arm64-v8a" value="1160289" />
```

and restarting WeChat—without forcing `xweb_using_core_version.xml`—caused WeChat itself to regenerate:

```xml
<boolean name="using_core_version_1160289" value="true" />
```

A newly started `com.tencent.mm:appbrand0` then mapped:

```text
app_xweb_data/xweb_1160289/extracted_xwalkcore/libxwebcore.so
```

confirming that Pinus/XWeb 1160289 was genuinely active again.

## v1.2.2 fix

v1.2.2 treats `XWALKINFOS.xml` as part of the protected XWeb state:

1. Static-runtime recovery also ensures `back_core_version_for_arm64-v8a=1160289`.
2. If the static runtime is healthy but metadata is reset to `-1`, only the metadata is repaired.
3. BusyBox `inotifyd` watches XWALKINFOS write, close-write, delete, move, and inode-loss events.
4. If the metadata file is replaced, the watcher re-arms against the new inode.
5. Metadata-only recovery does not rewrite the approximately 240 MB XWeb runtime.
6. Metadata repairs also update the Magisk last-restore timestamp.

## Metadata-only device test

With all XWeb 1160289 static files healthy, the authoritative field was deliberately changed to `-1`.

Within roughly six seconds the guard restored it to `1160289`. During the test:

- `libxwebcore.so` mtime did not change;
- the watcher remained alive;
- the Magisk Last restore timestamp updated;
- the guard log recorded `RESTORED: XWALKINFOS core metadata 1160289`.

v1.2.2 therefore protects both the static XWeb runtime and the metadata required for WeChat to select it.
