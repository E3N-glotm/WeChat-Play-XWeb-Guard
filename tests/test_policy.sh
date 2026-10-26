#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail() { echo "FAIL: $*" >&2; exit 1; }

grep -q '^author=E3N$' "$ROOT/module/module.prop" || fail "module author must be E3N"
grep -q '^version=1.2.4$' "$ROOT/module/module.prop" || fail "unexpected module version"
grep -q '^versionCode=124$' "$ROOT/module/module.prop" || fail "unexpected module versionCode"
grep -Fq 'description=XWeb 1160289 内核守护｜最近恢复：从未' "$ROOT/module/module.prop" || fail "initial Magisk last-restore description missing"
grep -q 'XWEB_VERSION=1160289' "$ROOT/module/bin/common.sh" || fail "XWeb version guard missing"
grep -q 'EXPECTED_SNAPSHOT_SHA=09347ca1fb5b250fd79460b2b22083400046599fa5714af93124f2d1507f7619' "$ROOT/module/bin/common.sh" || fail "hardcoded bundled snapshot digest missing"
grep -q 'record_restore_timestamp' "$ROOT/module/bin/repair.sh" || fail "successful repair does not record timestamp"
grep -q 'LAST_RESTORE=' "$ROOT/module/bin/common.sh" || fail "persistent restore timestamp path missing"
grep -q 'sync_module_description' "$ROOT/module/bin/common.sh" || fail "dynamic Magisk description updater missing"
grep -q 'Last successful restore:' "$ROOT/module/action.sh" || fail "Action does not display last restore time"
grep -q 'XWALKINFOS.xml' "$ROOT/module/bin/common.sh" || fail "XWALKINFOS metadata path missing"
grep -q 'back_core_version_for_arm64-v8a' "$ROOT/module/bin/common.sh" || fail "XWeb core-version metadata repair missing"
grep -q 'xwalk_meta_healthy' "$ROOT/module/bin/repair.sh" || fail "repair path does not validate XWALKINFOS"
grep -q 'repair_xwalk_meta' "$ROOT/module/bin/repair.sh" || fail "repair path does not restore XWALKINFOS"
grep -q 'META:cwDMx' "$ROOT/module/bin/watch.sh" || fail "watcher does not monitor XWALKINFOS changes"
grep -q '"$META"' "$ROOT/module/bin/event.sh" || fail "event handler does not process XWALKINFOS"

if grep -R -E 'EXPECTED_VERSION_CODE|validated_wechat|strict_build|recovery_allowed|versionCode=3141' "$ROOT/module" --include='*.sh' --include='*.prop' >/dev/null 2>&1; then
    fail "WeChat build/version gating must not exist anywhere in the module"
fi

if grep -R -E 'for F in \+|printf .%s\\n. \+' "$ROOT/module/bin" --include='*.sh' >/dev/null 2>&1; then
    fail "malformed shell plus tokens detected"
fi

grep -q 'apk/base.apk' "$ROOT/module/bin/snapshot.sh" || fail "base.apk is not part of the local snapshot"
grep -q 'libxwebcore.so' "$ROOT/module/bin/snapshot.sh" || fail "libxwebcore.so is not part of the local snapshot"
grep -q 'zip/base.zip' "$ROOT/module/bin/snapshot.sh" || fail "base.zip is not part of the local snapshot"
grep -q 'privacy guard rejected snapshot contents' "$ROOT/module/bin/snapshot.sh" || fail "snapshot privacy guard missing"

if grep -R -E 'com.google.android.gms.appid.xml|FCM token' "$ROOT/module/bin" >/dev/null 2>&1; then
    fail "XWeb guard must not depend on FCM credentials"
fi

grep -q 'app_data_ready || exit 0' "$ROOT/module/bin/repair.sh" || fail "full app-data reset guard missing"
grep -q 'WeChat process was not killed' "$ROOT/module/bin/repair.sh" || fail "non-disruptive repair invariant missing"
grep -q 'inotifyd' "$ROOT/module/bin/watch.sh" || fail "event-driven watcher missing"

echo "policy regression: PASS"
