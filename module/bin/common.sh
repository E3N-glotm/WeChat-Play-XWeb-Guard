#!/system/bin/sh

[ -n "$MODDIR" ] || MODDIR=${0%/*}/..
RUNDIR=/data/adb/wechat_xweb_guard
BB=/data/adb/magisk/busybox
[ -x "$BB" ] || BB=/system/xbin/busybox
[ -x "$BB" ] || BB=busybox

WXPKG=com.tencent.mm
EXPECTED_VERSION_CODE=3141
XWEB_VERSION=1160289

D=/data_mirror/data_ce/null/0/$WXPKG
P=$D/app_xweb_data
X=$P/xweb_$XWEB_VERSION
PREF=$D/shared_prefs/xweb_using_core_version.xml

SNAPSHOT=$RUNDIR/core_$XWEB_VERSION.tar
SNAPSHOT_SHA=$RUNDIR/core_$XWEB_VERSION.sha256
LOG=$RUNDIR/guard.log
LOCK=$RUNDIR/repair.lock
WATCHER_PID=$RUNDIR/watcher.pid

CORE_SIZE=135166832
BASE_APK_SIZE=33171682
BASE_ZIP_SIZE=70436321

ensure_rundir() {
    mkdir -p "$RUNDIR"
    chmod 700 "$RUNDIR" 2>/dev/null || true
}

log_msg() {
    ensure_rundir
    echo "$(date '+%F %T') $*" >> "$LOG"
    lines=$(wc -l < "$LOG" 2>/dev/null || echo 0)
    if [ "$lines" -gt 500 ] 2>/dev/null; then
        tail -n 300 "$LOG" > "$LOG.tmp" && mv -f "$LOG.tmp" "$LOG"
    fi
}

wechat_version_code() {
    dumpsys package "$WXPKG" 2>/dev/null \
        | grep -m1 'versionCode=' \
        | sed -n 's/.*versionCode=\([0-9]*\).*/\1/p'
}

supported_wechat() {
    [ "$(wechat_version_code)" = "$EXPECTED_VERSION_CODE" ]
}

live_core_healthy() {
    [ "$(stat -c %s "$X/extracted_xwalkcore/libxwebcore.so" 2>/dev/null)" = "$CORE_SIZE" ] &&
    [ "$(stat -c %s "$X/apk/base.apk" 2>/dev/null)" = "$BASE_APK_SIZE" ] &&
    [ "$(stat -c %s "$X/zip/base.zip" 2>/dev/null)" = "$BASE_ZIP_SIZE" ] &&
    [ -s "$X/extracted_xwalkcore/filelist.config" ] &&
    [ -s "$X/extracted_xwalkcore/dummy.dat" ]
}

snapshot_valid() {
    [ -s "$SNAPSHOT" ] && [ -s "$SNAPSHOT_SHA" ] || return 1
    (cd "$RUNDIR" && "$BB" sha256sum -c "${SNAPSHOT_SHA##*/}" >/dev/null 2>&1)
}

app_data_ready() {
    [ -d "$D/shared_prefs" ] && [ -d "$D/MicroMsg" ]
}

app_context() {
    ls -Zd "$D/shared_prefs" 2>/dev/null | awk '{print $1}'
}
