#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/bin/common.sh"

echo "=== WeChat Play XWeb Guard ==="
sync_module_description || true
echo "Module: 1.2.1 / author E3N"
echo "WeChat versionCode: $(wechat_version_code)"
echo "Last successful restore: $(last_restore_display)"
if validated_wechat; then
    echo "Build validation: validated target ($EXPECTED_VERSION_CODE)"
else
    if strict_build_mode; then
        echo "Build validation: UNVALIDATED; strict-build mode blocks recovery"
    else
        echo "Build validation: UNVALIDATED; recovery remains enabled by user policy"
    fi
fi
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
