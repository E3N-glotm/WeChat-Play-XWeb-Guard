#!/system/bin/sh
. "${0%/*}/common.sh"

EV=$1
WATCH=$2
CHILD=$3
REARM=0

case "$EV" in *d*|*m*|*x*|*o*) ;; *) exit 0 ;; esac

case "$WATCH" in
    "$D")
        [ "$CHILD" = app_xweb_data ] || exit 0
        REARM=1
        ;;
    "$P")
        [ "$CHILD" = "xweb_$XWEB_VERSION" ] || [ -z "$CHILD" ] || exit 0
        REARM=1
        ;;
    "$X")
        case "$CHILD" in apk|zip|extracted_xwalkcore|'') REARM=1 ;; *) exit 0 ;; esac
        ;;
    "$X/extracted_xwalkcore")
        case "$CHILD" in
            libxwebcore.so|libffmpeg.so|libWXAMSDK.so|filelist.config|dummy.dat|media_player_extension.apk|reslist.config|'') ;;
            *) exit 0 ;;
        esac
        ;;
    "$X/apk")
        case "$CHILD" in base.apk|'') ;; *) exit 0 ;; esac
        ;;
    "$X/zip")
        case "$CHILD" in base.zip|'') ;; *) exit 0 ;; esac
        ;;
    *) exit 0 ;;
esac

"$MODDIR/bin/repair.sh" event

# inotify watches attach to inodes. Recovered directories have new inodes, so
# stop only our parent inotifyd and let watch.sh rebuild the watch set.
if [ "$REARM" = 1 ]; then
    PP=$(awk '/^PPid:/ {print $2}' "/proc/$$/status" 2>/dev/null)
    case "$PP" in ''|*[!0-9]*) exit 0;; esac
    [ "$PP" -gt 1 ] 2>/dev/null || exit 0
    CMD=$(tr '\000' ' ' < "/proc/$PP/cmdline" 2>/dev/null)
    case "$CMD" in *inotifyd*) kill -TERM "$PP" 2>/dev/null ;; esac
fi
exit 0
