#!/system/bin/sh
MODDIR=${0%/*}
RUNDIR=/data/adb/wechat_xweb_guard

if [ -s "$RUNDIR/watcher.pid" ]; then
    PID=$(cat "$RUNDIR/watcher.pid" 2>/dev/null)
    [ -n "$PID" ] && kill "$PID" 2>/dev/null || true
fi

# Remove only the guard's private snapshot/log/state. Do not delete or alter
# the XWeb core currently installed inside WeChat.
rm -rf "$RUNDIR"
exit 0
