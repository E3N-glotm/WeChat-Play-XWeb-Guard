#!/system/bin/sh

ui_print "============================================"
ui_print " WeChat Play XWeb Guard v1.2.1"
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

# v1.2.0 bundles the authorized, privacy-scrubbed XWeb 1160289 static runtime
# snapshot. Install it into the private runtime directory after SHA256
# verification so only one persistent copy remains after installation.
BUNDLED="$MODPATH/assets/core_1160289.tar"
BUNDLED_SHA="$MODPATH/assets/core_1160289.sha256"

if [ -s "$BUNDLED" ] && [ -s "$BUNDLED_SHA" ]; then
    expected_hash=$(awk 'NR==1 {print $1}' "$BUNDLED_SHA")
    actual_hash=$(/data/adb/magisk/busybox sha256sum "$BUNDLED" | awk '{print $1}')
    hardcoded_hash=09347ca1fb5b250fd79460b2b22083400046599fa5714af93124f2d1507f7619
    if [ "$expected_hash" = "$hardcoded_hash" ] && [ "$actual_hash" = "$hardcoded_hash" ]; then
        rm -f "$RUNDIR/core_1160289.tar.tmp"
        mv "$BUNDLED" "$RUNDIR/core_1160289.tar.tmp" 2>/dev/null || {
            cp -p "$BUNDLED" "$RUNDIR/core_1160289.tar.tmp" || abort "Cannot stage bundled XWeb snapshot"
            rm -f "$BUNDLED"
        }
        verify_hash=$(/data/adb/magisk/busybox sha256sum "$RUNDIR/core_1160289.tar.tmp" | awk '{print $1}')
        [ "$verify_hash" = "$hardcoded_hash" ] || abort "Bundled XWeb snapshot failed post-copy verification"
        printf '%s  core_1160289.tar\n' "$hardcoded_hash" > "$RUNDIR/core_1160289.sha256"
        mv -f "$RUNDIR/core_1160289.tar.tmp" "$RUNDIR/core_1160289.tar"
        chmod 600 "$RUNDIR/core_1160289.tar" "$RUNDIR/core_1160289.sha256"
        ui_print "- Bundled XWeb 1160289 snapshot verified and installed."
    else
        abort "Bundled XWeb snapshot SHA256 mismatch"
    fi
else
    abort "Bundled XWeb 1160289 snapshot is missing"
fi

# Upgrade path from the private prototype is kept only as a fallback for
# development builds that intentionally omit the bundled asset.
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

ui_print "- XWeb 1160289 recovery is available immediately after install."
ui_print "- Build changes only trigger a warning; recovery remains enabled."
MODDIR=$MODPATH
. "$MODPATH/bin/common.sh"
sync_module_description || true
ui_print "- Last restore shown in Magisk: $(last_restore_display)"
ui_print "- Optional strict mode: touch /data/adb/wechat_xweb_guard/strict_build"
ui_print "- Reboot after installation."
