#!/system/bin/sh
. "${0%/*}/common.sh"

MODE=${1:-ensure}
ensure_rundir

if ! validated_wechat; then
    log_msg "WARNING: WeChat versionCode=$(wechat_version_code) is unvalidated for XWeb $XWEB_VERSION"
fi
recovery_allowed || {
    log_msg "SKIP: strict-build mode blocks unvalidated WeChat versionCode=$(wechat_version_code)"
    exit 10
}

live_core_healthy || {
    [ "$MODE" = install ] && log_msg "snapshot skipped: live XWeb $XWEB_VERSION is not healthy"
    exit 11
}

if [ "$MODE" != refresh ] && snapshot_valid; then
    exit 0
fi

TMP=$RUNDIR/.core_$XWEB_VERSION.tar.$$
TMPSHA=$RUNDIR/.core_$XWEB_VERSION.sha256.$$
rm -f "$TMP" "$TMPSHA"

# Static runtime files only. Do not capture WebView profiles, cookies, history,
# chat data, account data, or anything under X/Default.
"$BB" tar -C "$X" -cf "$TMP" \
    apk/base.apk \
    extracted_xwalkcore/dummy.dat \
    extracted_xwalkcore/filelist.config \
    extracted_xwalkcore/reslist.config \
    extracted_xwalkcore/libxwebcore.so \
    extracted_xwalkcore/libWXAMSDK.so \
    extracted_xwalkcore/libffmpeg.so \
    extracted_xwalkcore/media_player_extension.apk \
    zip/base.zip || {
        rm -f "$TMP" "$TMPSHA"
        log_msg "ERROR: local snapshot creation failed"
        exit 12
    }

if "$BB" tar -tf "$TMP" | grep -Ei '(^|/)(Default|Profile|Cookies|History|Login|MicroMsg)(/|$)' >/dev/null 2>&1; then
    rm -f "$TMP" "$TMPSHA"
    log_msg "ERROR: privacy guard rejected snapshot contents"
    exit 13
fi

hash=$("$BB" sha256sum "$TMP" | awk '{print $1}')
case "$hash" in ''|*[!0-9a-fA-F]*) rm -f "$TMP"; exit 14;; esac
printf '%s  %s\n' "$hash" "${SNAPSHOT##*/}" > "$TMPSHA"
chmod 600 "$TMP" "$TMPSHA"
mv -f "$TMP" "$SNAPSHOT"
mv -f "$TMPSHA" "$SNAPSHOT_SHA"

snapshot_valid || {
    log_msg "ERROR: local snapshot verification failed"
    exit 15
}

log_msg "SNAPSHOT: captured local XWeb $XWEB_VERSION static runtime files"
exit 0
