#!/system/bin/sh

[ -n "$MODDIR" ] || MODDIR=${0%/*}/..
RUNDIR=/data/adb/wechat_xweb_guard
BB=/data/adb/magisk/busybox
[ -x "$BB" ] || BB=/system/xbin/busybox
[ -x "$BB" ] || BB=busybox

WXPKG=com.tencent.mm
EXPECTED_VERSION_CODE=3141
XWEB_VERSION=1160289
EXPECTED_SNAPSHOT_SHA=09347ca1fb5b250fd79460b2b22083400046599fa5714af93124f2d1507f7619

D=/data_mirror/data_ce/null/0/$WXPKG
SP=$D/shared_prefs
P=$D/app_xweb_data
X=$P/xweb_$XWEB_VERSION
PREF=$SP/xweb_using_core_version.xml
META=$SP/XWALKINFOS.xml

SNAPSHOT=$RUNDIR/core_$XWEB_VERSION.tar
SNAPSHOT_SHA=$RUNDIR/core_$XWEB_VERSION.sha256
LOG=$RUNDIR/guard.log
LOCK=$RUNDIR/repair.lock
WATCHER_PID=$RUNDIR/watcher.pid
LAST_RESTORE=$RUNDIR/last_restore.txt

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

validated_wechat() {
    [ "$(wechat_version_code)" = "$EXPECTED_VERSION_CODE" ]
}

strict_build_mode() {
    [ -f "$RUNDIR/strict_build" ]
}

recovery_allowed() {
    validated_wechat && return 0
    strict_build_mode && return 1
    return 0
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
    [ -d "$SP" ] && [ -d "$D/MicroMsg" ]
}

app_context() {
    ls -Zd "$SP" 2>/dev/null | awk '{print $1}'
}

xwalk_meta_healthy() {
    grep -Eq 'name="back_core_version_for_arm64-v8a"[[:space:]]+value="1160289"' "$META" 2>/dev/null
}

repair_xwalk_meta() {
    UIDN=$(stat -c %u "$D" 2>/dev/null) || return 1
    GIDN=$(stat -c %g "$D" 2>/dev/null) || return 1
    CTX=$(app_context)
    [ -n "$CTX" ] || return 1
    Q=$SP/.XWALKINFOS.guard_$$

    if [ -f "$META" ] && grep -q '</map>' "$META" 2>/dev/null; then
        awk '
            BEGIN { done=0 }
            /name="back_core_version_for_arm64-v8a"/ {
                print "    <int name=\"back_core_version_for_arm64-v8a\" value=\"1160289\" />"
                done=1
                next
            }
            /<\/map>/ && !done {
                print "    <int name=\"back_core_version_for_arm64-v8a\" value=\"1160289\" />"
                done=1
            }
            { print }
        ' "$META" > "$Q" || {
            rm -f "$Q"
            return 1
        }
    else
        printf "%s\n" +            "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>" +            '<map>' +            '    <int name="back_core_version_for_arm64-v8a" value="1160289" />' +            '</map>' > "$Q"
    fi

    chown "$UIDN:$GIDN" "$Q"
    chmod 660 "$Q"
    chcon "$CTX" "$Q"
    mv -f "$Q" "$META"
    xwalk_meta_healthy
}

ensure_using_core_pref() {
    grep -Fq "using_core_version_$XWEB_VERSION" "$PREF" 2>/dev/null && return 0
    UIDN=$(stat -c %u "$D" 2>/dev/null) || return 1
    GIDN=$(stat -c %g "$D" 2>/dev/null) || return 1
    CTX=$(app_context)
    [ -n "$CTX" ] || return 1
    Q=$SP/.xweb_guard_pref_$$
    printf "%s\n" +        "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>" +        '<map>' +        "    <boolean name=\"using_core_version_$XWEB_VERSION\" value=\"true\" />" +        '</map>' > "$Q"
    chown "$UIDN:$GIDN" "$Q"
    chmod 660 "$Q"
    chcon "$CTX" "$Q"
    mv -f "$Q" "$PREF"
}

last_restore_display() {
    if [ -s "$LAST_RESTORE" ]; then
        tr -d '\r\n' < "$LAST_RESTORE"
    else
        printf '%s' never
    fi
}

sync_module_description() {
    ensure_rundir
    PROP=$MODDIR/module.prop
    [ -f "$PROP" ] || return 0

    TS=$(last_restore_display)
    DESC="XWeb 1160289 guard | Last restore: $TS"
    TMP=$RUNDIR/.module_prop.$$

    awk -v d="$DESC" '
        BEGIN { found=0 }
        /^description=/ {
            print "description=" d
            found=1
            next
        }
        { print }
        END {
            if (!found) print "description=" d
        }
    ' "$PROP" > "$TMP" || {
        rm -f "$TMP"
        return 1
    }

    cat "$TMP" > "$PROP"
    chmod 0644 "$PROP" 2>/dev/null || true
    rm -f "$TMP"
}

record_restore_timestamp() {
    ensure_rundir
    TS=$(date '+%Y-%m-%d %H:%M:%S %z')
    printf '%s\n' "$TS" > "$LAST_RESTORE"
    chmod 0600 "$LAST_RESTORE" 2>/dev/null || true
    sync_module_description || true
}
