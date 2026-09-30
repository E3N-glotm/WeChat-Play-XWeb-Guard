#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VERSION="$(awk -F= '$1=="version" {print $2}' "$ROOT/module/module.prop")"
OUT="$ROOT/dist"
STAGE="$ROOT/.build-stage.$$"
ZIP="$OUT/WeChat-Play-XWeb-Guard-v${VERSION}.zip"

trap 'rm -rf "$STAGE"' EXIT INT TERM
rm -rf "$STAGE"
mkdir -p "$STAGE" "$OUT"
rm -f "$ZIP"
cp -a "$ROOT/module/." "$STAGE/"

# Git on Windows can expose CRLF depending on checkout settings. Normalize
# text files only; NEVER run sed across bundled binary assets.
find "$STAGE" -type f \( -name '*.sh' -o -name '*.prop' -o -name '*.txt' -o -name '*.md' \) -exec sed -i 's/\r$//' {} +
(
    cd "$STAGE"
    zip -qr "$ZIP" . -x '*.DS_Store'
)

echo "$ZIP"
