#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/bin/common.sh"

echo "=== WeChat Play XWeb Guard ==="
echo "Module: 1.1.0 / author E3N"
echo "WeChat versionCode: $(wechat_version_code)"
if live_core_healthy; then
    echo "Live XWeb $XWEB_VERSION: healthy"
else
    echo "Live XWeb $XWEB_VERSION: missing/incomplete"
fi
if snapshot_valid; then
    echo "Protected local snapshot: valid"
    ls -lh "$SNAPSHOT" 2>/dev/null
else
    echo "Protected local snapshot: unavailable"
fi
if [ -s "$WATCHER_PID" ] && kill -0 "$(cat "$WATCHER_PID")" 2>/dev/null; then
    echo "Watcher: running (PID $(cat "$WATCHER_PID"))"
else
    echo "Watcher: not running"
fi

if live_core_healthy && ! snapshot_valid; then
    "$MODDIR/bin/snapshot.sh" ensure && echo "Snapshot bootstrap: success"
fi
if ! live_core_healthy && snapshot_valid; then
    "$MODDIR/bin/repair.sh" action && echo "Repair check: finished"
fi

echo "Recent log:"
tail -n 30 "$LOG" 2>/dev/null || true
