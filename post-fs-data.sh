#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode

# If you for some reason do not want all your certificates moved from the user store to the system store, you can specify which certificates to move by replacing the * with the name of the certificate; i.e.,

# mv -f /data/misc/user/0/cacerts-added/12abc345.0 $MODDIR/system/etc/security/cacerts

mv -f /data/misc/user/0/cacerts-added/* $MODDIR/system/etc/security/cacerts
chown 0:0 $MODDIR/system/etc/security/cacerts/*
chcon u:object_r:system_file:s0 $MODDIR/system/etc/security/cacerts/*
