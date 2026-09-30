#!/system/bin/sh
. "${0%/*}/common.sh"

ensure_rundir
echo $$ > "$WATCHER_PID"
trap 'rm -f "$WATCHER_PID"' EXIT HUP INT TERM

while :; do
    # CE storage may be unavailable until first unlock after boot.
    [ -d "$D/shared_prefs" ] && [ -d "$P" ] || {
        sleep 8
        continue
    }

    # Normally v1.2.0 already installed the bundled verified snapshot.
    # Keep local bootstrap as a fallback if the private snapshot is manually
    # removed while a healthy XWeb 1160289 still exists.
    snapshot_valid || "$MODDIR/bin/snapshot.sh" ensure >/dev/null 2>&1 || true
    "$MODDIR/bin/repair.sh" boot

    # No periodic scanning while healthy: inotifyd sleeps in the kernel until
    # a relevant path is removed/moved. Watch only paths that currently exist.
    if [ -d "$X/extracted_xwalkcore" ] && [ -d "$X/apk" ] && [ -d "$X/zip" ]; then
        "$BB" inotifyd "$MODDIR/bin/event.sh" \
            "$D:dm" "$P:dm" "$X:dm" \
            "$X/extracted_xwalkcore:dm" "$X/apk:dm" "$X/zip:dm"
    elif [ -d "$X" ]; then
        "$BB" inotifyd "$MODDIR/bin/event.sh" "$D:dm" "$P:dm" "$X:dm"
    else
        "$BB" inotifyd "$MODDIR/bin/event.sh" "$D:dm" "$P:dm"
    fi
    sleep 5
done
