#!/system/bin/sh
MODDIR=${0%/*}
RUNDIR=/data/adb/wechat_xweb_guard
PIDFILE=$RUNDIR/watcher.pid

[ -f "$MODDIR/disable" ] && exit 0
mkdir -p "$RUNDIR"
chmod 700 "$RUNDIR"
chmod 0755 "$MODDIR"/bin/*.sh 2>/dev/null || true

if [ -s "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        CMD=$(tr '\000' ' ' < "/proc/$PID/cmdline" 2>/dev/null)
        case "$CMD" in *"/wechat_xweb_guard/bin/watch.sh"*) exit 0 ;; esac
    fi
fi

/data/adb/magisk/busybox nohup /system/bin/sh "$MODDIR/bin/watch.sh" \
    </dev/null >/dev/null 2>&1 &
exit 0
