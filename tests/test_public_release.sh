#!/usr/bin/env bash
set -euo pipefail

ZIP=${1:?release zip required}
fail() { echo "FAIL: $*" >&2; exit 1; }

unzip -t "$ZIP" >/dev/null || fail "invalid release ZIP"
entries=$(unzip -Z1 "$ZIP")
case "$entries" in *"module.prop"*) ;; *) fail "module.prop missing" ;; esac
case "$entries" in *"bin/snapshot.sh"*) ;; *) fail "snapshot helper missing" ;; esac
case "$entries" in *"assets/core_1160289.tar"*) ;; *) fail "authorized XWeb 1160289 snapshot missing from release" ;; esac
case "$entries" in *"assets/core_1160289.sha256"*) ;; *) fail "snapshot checksum missing from release" ;; esac
case "$entries" in *"THIRD_PARTY_NOTICE.txt"*) ;; *) fail "third-party binary notice missing from release" ;; esac

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
unzip -p "$ZIP" assets/core_1160289.tar > "$TMP/core_1160289.tar"
unzip -p "$ZIP" assets/core_1160289.sha256 > "$TMP/core_1160289.sha256"
expected=$(awk 'NR==1 {print $1}' "$TMP/core_1160289.sha256")
actual=$(sha256sum "$TMP/core_1160289.tar" | awk '{print $1}')
[ "$expected" = "$actual" ] || fail "bundled snapshot SHA256 mismatch"

bad=$(tar -tf "$TMP/core_1160289.tar" | grep -Ei '(^|/)(Default|Profile|Cookies|History|Login|MicroMsg)(/|$)' || true)
[ -z "$bad" ] || fail "bundled snapshot contains private/profile paths"

count=$(tar -tf "$TMP/core_1160289.tar" | wc -l | tr -d ' ')
[ "$count" = 10 ] || fail "unexpected bundled snapshot file count: $count"

for f in \
    service.sh customize.sh action.sh uninstall.sh \
    bin/common.sh bin/snapshot.sh bin/repair.sh bin/watch.sh bin/event.sh
do
    if unzip -p "$ZIP" "$f" | grep -q $'\r'; then
        fail "CRLF found in packaged $f"
    fi
done

echo "public release regression: PASS"
