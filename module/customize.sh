#!/system/bin/sh

ui_print "============================================"
ui_print " WeChat Play XWeb Guard v1.1.0"
ui_print " Author: E3N"
ui_print "============================================"

case "$(getprop ro.product.cpu.abi)" in
    arm64-v8a) ;;
    *)
        ui_print "! This release is validated only on arm64-v8a."
        ui_print "! Installation aborted."
        abort "Unsupported ABI"
        ;;
esac

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm_recursive "$MODPATH/bin" 0 0 0755 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/customize.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

RUNDIR=/data/adb/wechat_xweb_guard
mkdir -p "$RUNDIR"
chmod 700 "$RUNDIR"

# Upgrade path from the private prototype: migrate its verified local snapshot
# out of the module directory. Public releases never bundle this file.
OLD=/data/adb/modules/wechat_xweb_guard
if [ ! -s "$RUNDIR/core_1160289.tar" ] &&
   [ -s "$OLD/core_1160289.tar" ] &&
   [ -s "$OLD/core_1160289.sha256" ]; then
    expected_hash=$(awk 'NR==1 {print $1}' "$OLD/core_1160289.sha256")
    old_hash=$(/data/adb/magisk/busybox sha256sum "$OLD/core_1160289.tar" | awk '{print $1}')
    if [ -n "$expected_hash" ] && [ "$old_hash" = "$expected_hash" ]; then
        cp -p "$OLD/core_1160289.tar" "$RUNDIR/core_1160289.tar.tmp"
        new_hash=$(/data/adb/magisk/busybox sha256sum "$RUNDIR/core_1160289.tar.tmp" | awk '{print $1}')
    else
        new_hash=
    fi
    if [ -n "$new_hash" ] && [ "$new_hash" = "$expected_hash" ]; then
        printf '%s  core_1160289.tar\n' "$expected_hash" > "$RUNDIR/core_1160289.sha256"
        mv -f "$RUNDIR/core_1160289.tar.tmp" "$RUNDIR/core_1160289.tar"
        chmod 600 "$RUNDIR/core_1160289.tar" "$RUNDIR/core_1160289.sha256"
        ui_print "- Migrated existing verified local XWeb snapshot."
    else
        rm -f "$RUNDIR/core_1160289.tar.tmp"
        ui_print "! Existing prototype snapshot migration failed verification."
    fi
fi

if /system/bin/sh "$MODPATH/bin/snapshot.sh" install >/dev/null 2>&1; then
    ui_print "- Local XWeb 1160289 snapshot is ready."
else
    ui_print "! No healthy compatible XWeb core was captured during install."
    ui_print "! The guard will stay passive and automatically capture one"
    ui_print "! when WeChat Play 8.0.77 (3141) has a healthy XWeb 1160289."
fi

ui_print "- No WeChat/XWeb binary is bundled in this ZIP."
ui_print "- Reboot after installation."
