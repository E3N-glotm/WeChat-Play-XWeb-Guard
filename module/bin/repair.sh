#!/system/bin/sh
. "${0%/*}/common.sh"

MODE=${1:-event}
ensure_rundir

if [ "$XWEB_GUARD_LOCK_HELD" != 1 ]; then
    export XWEB_GUARD_LOCK_HELD=1
    "$BB" flock -n "$LOCK" /system/bin/sh "$MODDIR/bin/repair.sh" "$MODE"
    exit $?
fi

# A deliberate uninstall / full app-data reset should not be reconstructed.
app_data_ready || exit 0
supported_wechat || exit 0
live_core_healthy && exit 0

[ "$MODE" = boot ] || sleep 3
live_core_healthy && exit 0

snapshot_valid || {
    log_msg "SKIP: no verified local XWeb snapshot is available"
    exit 2
}

UIDN=$(stat -c %u "$D")
GIDN=$(stat -c %g "$D")
CTX=$(app_context)
[ -n "$UIDN" ] && [ -n "$GIDN" ] && [ -n "$CTX" ] || {
    log_msg "ERROR: could not resolve WeChat ownership/SELinux context"
    exit 3
}

[ -d "$P" ] || {
    mkdir -p "$P"
    chown "$UIDN:$GIDN" "$P"
    chmod 771 "$P"
    chcon "$CTX" "$P"
}

S=$P/.xweb_guard_staging_$$
rm -rf "$S"
mkdir -m 700 "$S"

if ! "$BB" tar -xf "$SNAPSHOT" -C "$S"; then
    rm -rf "$S"
    log_msg "ERROR: snapshot extraction failed"
    exit 4
fi

mkdir -p "$S/dex"
chown -R "$UIDN:$GIDN" "$S"
chcon -R "$CTX" "$S"

if [ ! -d "$X" ]; then
    mv "$S" "$X"
else
    # Preserve WeChat-generated WebView profile and dex/oat state. Replace
    # only the static XWeb runtime files protected by the snapshot.
    mkdir -p "$X/apk" "$X/zip" "$X/extracted_xwalkcore" "$X/dex"
    for F in \
        apk/base.apk \
        zip/base.zip \
        extracted_xwalkcore/dummy.dat \
        extracted_xwalkcore/filelist.config \
        extracted_xwalkcore/reslist.config \
        extracted_xwalkcore/libxwebcore.so \
        extracted_xwalkcore/libWXAMSDK.so \
        extracted_xwalkcore/libffmpeg.so \
        extracted_xwalkcore/media_player_extension.apk
    do
        cp -p "$S/$F" "$X/$F" || {
            log_msg "ERROR: could not restore $F"
            rm -rf "$S"
            exit 5
        }
    done
    chown -R "$UIDN:$GIDN" "$X/apk" "$X/extracted_xwalkcore" "$X/zip"
    chcon -R "$CTX" "$X/apk" "$X/extracted_xwalkcore" "$X/zip"
    rm -rf "$S"
fi

chown "$UIDN:$GIDN" "$X"
chcon "$CTX" "$X"
chmod 700 "$X"

live_core_healthy || {
    log_msg "ERROR: post-restore files are incomplete"
    exit 6
}

if ! grep -Fq "using_core_version_$XWEB_VERSION" "$PREF" 2>/dev/null; then
    Q=$D/shared_prefs/.xweb_guard_pref_$$
    printf "%s\n" \
        "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>" \
        '<map>' \
        "    <boolean name=\"using_core_version_$XWEB_VERSION\" value=\"true\" />" \
        '</map>' > "$Q"
    chown "$UIDN:$GIDN" "$Q"
    chmod 660 "$Q"
    chcon "$CTX" "$Q"
    mv -f "$Q" "$PREF"
fi

log_msg "RESTORED: XWeb $XWEB_VERSION after $MODE; WeChat process was not killed"
exit 0
