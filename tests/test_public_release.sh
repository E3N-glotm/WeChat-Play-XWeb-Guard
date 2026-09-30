#!/usr/bin/env bash
set -euo pipefail

ZIP=${1:?release zip required}
fail() { echo "FAIL: $*" >&2; exit 1; }

unzip -t "$ZIP" >/dev/null || fail "invalid release ZIP"
unzip -l "$ZIP" | grep -q 'module.prop' || fail "module.prop missing"
unzip -l "$ZIP" | grep -q 'bin/snapshot.sh' || fail "snapshot helper missing"

# The public release must never redistribute the locally captured proprietary
# WeChat/XWeb runtime snapshot.
if unzip -l "$ZIP" | grep -Ei 'core_1160289\.tar|libxwebcore\.so|media_player_extension\.apk|zip/base\.zip'; then
    fail "release contains a WeChat/XWeb binary"
fi

if find "$PWD/module" -type f -size +1M | grep -q .; then
    fail "source tree contains an unexpectedly large bundled file"
fi

for f in \
    service.sh customize.sh action.sh uninstall.sh \
    bin/common.sh bin/snapshot.sh bin/repair.sh bin/watch.sh bin/event.sh
do
    if unzip -p "$ZIP" "$f" | grep -q $'\r'; then
        fail "CRLF found in packaged $f"
    fi
done

echo "public release regression: PASS"
