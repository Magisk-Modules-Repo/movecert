##########################################################################################
#
# MMT Extended Utility Functions
#
##########################################################################################

abort() {
  ui_print "$1"
  rm -rf $MODPATH 2>/dev/null
  cleanup
  rm -rf $TMPDIR 2>/dev/null
  exit 1
}

cleanup() {
  rm -rf $MODPATH/common 2>/dev/null
  ui_print " "
  ui_print "    **************************************"
  ui_print "    *   MMT Extended by Zackptg5 @ XDA   *"
  ui_print "    **************************************"
  ui_print " "
  $DEBUG && debug_log
}

debug_log() {
  set +x
  echo -e "***---Device Info---***" > $LOGFILE-tmp.log
  echo -e "\n---Props---\n" >> $LOGFILE-tmp.log
  getprop >> $LOGFILE-tmp.log
  echo -e "\n\n***---Magisk Info---***" >> $LOGFILE-tmp.log
  echo -e "\n---Magisk Version---\n\n$MAGISK_VER_CODE" >> $LOGFILE-tmp.log
  echo -e "\n---Installed Modules---\n" >> $LOGFILE-tmp.log
  ls $NVBASE/modules >> $LOGFILE-tmp.log
  echo -e "\n---Last Magisk Log---\n" >> $LOGFILE-tmp.log
  cat /cache/magisk.log >> $LOGFILE-tmp.log
  echo -e "\n\n***---MMT Extended Debug Info---***" >> $LOGFILE-tmp.log
  if [ -d "$MODPATH" ]; then
    echo -e "\n---Installed Files---\n" >> $LOGFILE-tmp.log
    grep "^+* cp_ch" $LOGFILE.log | sed 's/.* //g' >> $LOGFILE-tmp.log
    sed -i -e "\|$TMPDIR/|d" -e "\|$MODPATH|d" $LOGFILE-tmp.log
    find $MODPATH -type f >> $LOGFILE-tmp.log
    echo -e "\n---Installed Boot Scripts---\n" >> $LOGFILE-tmp.log
    grep "^+* install_script" $LOGFILE.log | sed -e 's/.* //g' -e 's/^-.* //g' >> $LOGFILE-tmp.log
    echo -e "\n---Installed Prop Files---\n" >> $LOGFILE-tmp.log
    grep "^+* prop_process" $LOGFILE.log | sed 's/.* //g' >> $LOGFILE-tmp.log
  fi
  echo -e "\n---Shell & MMT Extended Variables---\n" >> $LOGFILE-tmp.log
  (set) >> $LOGFILE-tmp.log
  echo -e "\n---(Un)Install Log---\n" >> $LOGFILE-tmp.log
  echo "$(cat $LOGFILE.log)" >> $LOGFILE-tmp.log
  mv -f $LOGFILE-tmp.log $LOGFILE.log
}

device_check() {
  local PROP=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  for i in /system /vendor /odm /product; do
    if [ -f $i/build.prop ]; then
      for j in "ro.product.device" "ro.build.product" "ro.product.vendor.device" "ro.vendor.product.device"; do
        [ "$(sed -n "s/^$j=//p" $i/build.prop 2>/dev/null | head -n 1 | tr '[:upper:]' '[:lower:]')" == "$PROP" ] && return 0
      done
    fi
  done
  return 1
}

run_addons() {
  local OPT=`getopt -o mpi -- "$@"` NAME PNAME
  eval set -- "$OPT"
  while true; do
    case "$1" in
      -m) NAME=main; shift;;
      -p) NAME=preinstall; PNAME="Preinstall"; shift;;
      -i) NAME=install; PNAME="Install"; shift;;
      --) shift; break;;
    esac
  done
  if [ "$(ls -A $MODPATH/common/addon/*/$NAME.sh 2>/dev/null)" ]; then
    [ -z $PNAME ] || { ui_print " "; ui_print "- Running $PNAME Addons -"; }
    for i in $MODPATH/common/addon/*/$NAME.sh; do
      ui_print "  Running $(echo $i | sed -r "s|$MODPATH/common/addon/(.*)/$NAME.sh|\1|")..."
      . $i
    done
    [ -z $PNAME ] || { ui_print " "; ui_print "- `echo $PNAME`ing (cont) -"; }
  fi
}

cp_ch() {
  local OPT=`getopt -o inr -- "$@"` BAK=true UBAK=true FOL=false
  eval set -- "$OPT"
  while true; do
    case "$1" in
      -n) UBAK=false; shift;;
      -r) FOL=true; shift;;
      --) shift; break;;
      *) abort "Invalid cp_ch argument $1! Aborting!";;
    esac
  done
  local SRC="$1" DEST="$2" OFILES="$1"
  $FOL && local OFILES=$(find $SRC -type f 2>/dev/null)
  [ -z $3 ] && PERM=0644 || PERM=$3
  case "$DEST" in
    $TMPDIR/*|$MODULEROOT/*|$NVBASE/modules/$MODID/*) BAK=false;;
  esac
  for OFILE in ${OFILES}; do
    if $FOL; then
      if [ "$(basename $SRC)" == "$(basename $DEST)" ]; then
        local FILE=$(echo $OFILE | sed "s|$SRC|$DEST|")
      else
        local FILE=$(echo $OFILE | sed "s|$SRC|$DEST/$(basename $SRC)|")
      fi
    else
      [ -d "$DEST" ] && local FILE="$DEST/$(basename $SRC)" || local FILE="$DEST"
    fi
    if $BAK && $UBAK; then
      [ ! "$(grep "$FILE$" $INFO 2>/dev/null)" ] && echo "$FILE" >> $INFO
      [ -f "$FILE" -a ! -f "$FILE~" ] && { mv -f $FILE $FILE~; echo "$FILE~" >> $INFO; }
    elif $BAK; then
      [ ! "$(grep "$FILE$" $INFO 2>/dev/null)" ] && echo "$FILE" >> $INFO
    fi
    install -D -m $PERM "$OFILE" "$FILE"
  done
}

install_script() {
  case "$1" in
    -l) shift; local INPATH=$NVBASE/service.d;;
    -p) shift; local INPATH=$NVBASE/post-fs-data.d;;
    *) local INPATH=$NVBASE/service.d;;
  esac
  [ "$(grep "#!/system/bin/sh" $1)" ] || sed -i "1i #!/system/bin/sh" $1
  local i; for i in "MODPATH" "LIBDIR" "MODID" "INFO" "MODDIR"; do
    case $i in
      "MODPATH") sed -i "1a $i=$NVBASE/modules/$MODID" $1;;
      "MODDIR") sed -i "1a $i=\${0%/*}" $1;;
      *) sed -i "1a $i=$(eval echo \$$i)" $1;;
    esac
  done
  [ "$1" == "$MODPATH/uninstall.sh" ] && return 0
  case $(basename $1) in
    post-fs-data.sh|service.sh) ;;
    *) cp_ch -n $1 $INPATH/$(basename $1) 0755;;
  esac
}

prop_process() {
  sed -i -e "/^#/d" -e "/^ *$/d" $1
  [ -f $MODPATH/system.prop ] || mktouch $MODPATH/system.prop
  while read LINE; do
    echo "$LINE" >> $MODPATH/system.prop
  done < $1
}

# Check for min/max api version
[ -z $MINAPI ] || { [ $API -lt $MINAPI ] && abort "! Your system API of $API is less than the minimum api of $MINAPI! Aborting!"; }
[ -z $MAXAPI ] || { [ $API -gt $MAXAPI ] && abort "! Your system API of $API is greater than the maximum api of $MAXAPI! Aborting!"; }

# Set variables
[ $API -lt 26 ] && DYNLIB=false
[ -z $DYNLIB ] && DYNLIB=false
[ -z $DEBUG ] && DEBUG=false
[ -e "$PERSISTDIR" ] && PERSISTMOD=$PERSISTDIR/magisk/$MODID
INFO=$NVBASE/modules/.$MODID-files
ORIGDIR="$MAGISKTMP/mirror"
if $DYNLIB; then
  LIBPATCH="\/vendor"
  LIBDIR=/system/vendor
else
  LIBPATCH="\/system"
  LIBDIR=/system
fi
if ! $BOOTMODE; then
  ui_print "- Only uninstall is supported in recovery"
  ui_print "  Uninstalling!"
  touch $MODPATH/remove
  [ -s $INFO ] && install_script $MODPATH/uninstall.sh || rm -f $INFO $MODPATH/uninstall.sh
  recovery_cleanup
  cleanup
  rm -rf $NVBASE/modules_update/$MODID $TMPDIR 2>/dev/null
  exit 0
fi

# Debug
if $DEBUG; then
  ui_print "- Debug mode"
  LOGFILE=/storage/emulated/0/Download/$MODID-debug
  ui_print "  Debug log will be written to: $LOGFILE.log"
  exec 2>$LOGFILE.log
  set -x
fi

# Extract files
ui_print "- Extracting module files"
unzip -o "$ZIPFILE" -x 'META-INF/*' 'common/functions.sh' -d $MODPATH >&2
[ -f "$MODPATH/common/addon.tar.xz" ] && tar -xf $MODPATH/common/addon.tar.xz -C $MODPATH/common 2>/dev/null

# Main addons
run_addons -m

# Remove files outside of module directory
ui_print "- Removing old files"

if [ -f $INFO ]; then
  while read LINE; do
    if [ "$(echo -n $LINE | tail -c 1)" == "~" ]; then
      continue
    elif [ -f "$LINE~" ]; then
      mv -f $LINE~ $LINE
    else
      rm -f $LINE
      while true; do
        LINE=$(dirname $LINE)
        [ "$(ls -A $LINE 2>/dev/null)" ] && break 1 || rm -rf $LINE
      done
    fi
  done < $INFO
  rm -f $INFO
fi

### Install
ui_print "- Installing"

run_addons -p
[ -f "$MODPATH/common/install.sh" ] && . $MODPATH/common/install.sh
run_addons -i

ui_print "   Installing for $ARCH SDK $API device..."
# Remove comments from files and place them, add blank line to end if not already present
for i in $(find $MODPATH -type f -name "*.sh" -o -name "*.prop" -o -name "*.rule"); do
  [ -f $i ] && { sed -i -e "/^#/d" -e "/^ *$/d" $i; [ "$(tail -1 $i)" ] && echo "" >> $i; } || continue
  case $i in
    "$MODPATH/service.sh") install_script -l $i;;
    "$MODPATH/post-fs-data.sh") install_script -p $i;;
    "$MODPATH/uninstall.sh") if [ -s $INFO ] || [ "$(head -n1 $MODPATH/uninstall.sh)" != "# Don't modify anything after this" ]; then
                               install_script $MODPATH/uninstall.sh
                             else
                               rm -f $INFO $MODPATH/uninstall.sh
                             fi;;
  esac
done

$IS64BIT || for i in $(find $MODPATH/system -type d -name "lib64"); do rm -rf $i 2>/dev/null; done  
[ -d "/system/priv-app" ] || mv -f $MODPATH/system/priv-app $MODPATH/system/app 2>/dev/null
[ -d "/system/xbin" ] || mv -f $MODPATH/system/xbin $MODPATH/system/bin 2>/dev/null
if $DYNLIB; then
  for FILE in $(find $MODPATH/system/lib* -type f 2>/dev/null | sed "s|$MODPATH/system/||"); do
    [ -s $MODPATH/system/$FILE ] || continue
    case $FILE in
      lib*/modules/*) continue;;
    esac
    mkdir -p $(dirname $MODPATH/system/vendor/$FILE)
    mv -f $MODPATH/system/$FILE $MODPATH/system/vendor/$FILE
    [ "$(ls -A `dirname $MODPATH/system/$FILE`)" ] || rm -rf `dirname $MODPATH/system/$FILE`
  done
  # Delete empty lib folders (busybox find doesn't have this capability)
  toybox find $MODPATH/system/lib* -type d -empty -delete >/dev/null 2>&1
fi

# Set permissions
ui_print " "
ui_print "- Setting Permissions"
set_perm_recursive $MODPATH 0 0 0755 0644
if [ -d $MODPATH/system/vendor ]; then
  set_perm_recursive $MODPATH/system/vendor 0 0 0755 0644 u:object_r:vendor_file:s0
  [ -d $MODPATH/system/vendor/app ] && set_perm_recursive $MODPATH/system/vendor/app 0 0 0755 0644 u:object_r:vendor_app_file:s0
  [ -d $MODPATH/system/vendor/etc ] && set_perm_recursive $MODPATH/system/vendor/etc 0 0 0755 0644 u:object_r:vendor_configs_file:s0
  [ -d $MODPATH/system/vendor/overlay ] && set_perm_recursive $MODPATH/system/vendor/overlay 0 0 0755 0644 u:object_r:vendor_overlay_file:s0
  for FILE in $(find $MODPATH/system/vendor -type f -name *".apk"); do
    [ -f $FILE ] && chcon u:object_r:vendor_app_file:s0 $FILE
  done
fi
set_permissions

# Complete install
cleanup
