#!/bin/sh

DOCSTRING="Usage: ./setup-frida-android.sh -a TARGET_ARCHITECTURE [-n BINARY_NAME_ON_TARGET] [-l DIR_WITH_FRIDA_LIBS]"
NAME='frida-server'

WORKDIR="$HOME/.config/frida-scripts"
ARCH=''

while [ "$1" != "" ];
do
case $1 in
    -a |--arch )
    shift
    ARCH=$1
    ;;
    -n|--name)
    shift
    NAME=$1
    exit
    ;;
    -l|--libdir)
    shift
    WORKDIR=$1
    exit
    ;;
    -h|--help)
    echo $DOCSTRING
    exit
    ;;
    *)
    echo $1
    echo $DOCSTRING
    exit
    ;;
esac
shift
done

VERSION=`cat $WORKDIR/LATEST_RELEASE`

if [[ -z "$ARCH" ]]; then
    echo "No target architecture specified not found! Exiting!"
    echo $DOCSTRING
    exit -1
fi

if [[ -z "$NAME" ]]; then
  NAME='frida'
fi

#echo Executing: adb root
#adb root

echo Executing: adb push $WORKDIR/frida-libs/frida-server-$VERSION-android-$ARCH /data/local/tmp/$NAME
adb push $WORKDIR/frida-libs/frida-server-$VERSION-android-$ARCH /data/local/tmp/$NAME

echo Executing: adb shell "chmod 755 /data/local/tmp/$NAME"
adb shell "su 0 chmod 755 /data/local/tmp/$NAME"

echo Executing: adb shell "/data/local/tmp/$NAME &"
adb shell "su 0 /data/local/tmp/$NAME "&

frida-ps -U
