#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fail() { echo "FAIL: $*" >&2; exit 1; }

grep -q '^author=E3N$' "$ROOT/module/module.prop" +    || fail "module author must be E3N"
grep -q '^version=1.1.0$' "$ROOT/module/module.prop" +    || fail "unexpected module version"
grep -q 'EXPECTED_VERSION_CODE=3141' "$ROOT/module/bin/common.sh" +    || fail "WeChat version guard missing"
grep -q 'XWEB_VERSION=1160289' "$ROOT/module/bin/common.sh" +    || fail "XWeb version guard missing"

grep -q 'apk/base.apk' "$ROOT/module/bin/snapshot.sh" +    || fail "base.apk is not part of the local snapshot"
grep -q 'libxwebcore.so' "$ROOT/module/bin/snapshot.sh" +    || fail "libxwebcore.so is not part of the local snapshot"
grep -q 'zip/base.zip' "$ROOT/module/bin/snapshot.sh" +    || fail "base.zip is not part of the local snapshot"
grep -q 'privacy guard rejected snapshot contents' "$ROOT/module/bin/snapshot.sh" +    || fail "snapshot privacy guard missing"

if grep -R -E 'com.google.android.gms.appid.xml|FCM token' "$ROOT/module/bin" >/dev/null 2>&1; then
    fail "XWeb guard must not depend on FCM credentials"
fi

grep -q 'app_data_ready || exit 0' "$ROOT/module/bin/repair.sh" +    || fail "full app-data reset guard missing"
grep -q 'WeChat process was not killed' "$ROOT/module/bin/repair.sh" +    || fail "non-disruptive repair invariant missing"
grep -q 'inotifyd' "$ROOT/module/bin/watch.sh" +    || fail "event-driven watcher missing"

echo "policy regression: PASS"
