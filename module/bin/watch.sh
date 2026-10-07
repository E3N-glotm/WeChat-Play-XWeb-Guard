#!/system/bin/sh
. "${0%/*}/common.sh"

ensure_rundir
echo $$ > "$WATCHER_PID"
trap 'rm -f "$WATCHER_PID"' EXIT HUP INT TERM

while :; do
    # CE storage may be unavailable until first unlock after boot.
    [ -d "$SP" ] && [ -d "$P" ] || {
        sleep 8
        continue
    }

    # The bundled snapshot is installed into the private runtime directory.
    # Keep local bootstrap as a fallback if that snapshot is manually removed
    # while a healthy XWeb 1160289 still exists.
    snapshot_valid || "$MODDIR/bin/snapshot.sh" ensure >/dev/null 2>&1 || true
    "$MODDIR/bin/repair.sh" boot

    # No periodic scanning while healthy: inotifyd sleeps in the kernel until
    # a relevant XWeb path or XWALKINFOS metadata event occurs.
    set -- "$D:dm" "$P:dm"
    [ -d "$X" ] && set -- "$@" "$X:dm"
    [ -d "$X/extracted_xwalkcore" ] && set -- "$@" "$X/extracted_xwalkcore:dm"
    [ -d "$X/apk" ] && set -- "$@" "$X/apk:dm"
    [ -d "$X/zip" ] && set -- "$@" "$X/zip:dm"
    if [ -f "$META" ]; then
        set -- "$@" "$META:cwDMx"
    else
        set -- "$@" "$SP:nymd"
    fi

    "$BB" inotifyd "$MODDIR/bin/event.sh" "$@"
    sleep 5
done
