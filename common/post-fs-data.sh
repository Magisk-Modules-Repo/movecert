#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode
# More info in the main Magisk thread

# If you for some reason do not want all your certificates moved from the user store to the system store, you can specify which certificates to move by replacing the * with the name of the certificate; i.e.,

# mv -f /data/misc/user/0/cacerts-added/12abc345.0 $MODDIR/system/etc/security/cacerts

mv -f /data/misc/user/0/cacerts-added/* $MODDIR/system/etc/security/cacerts
