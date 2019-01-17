#!/bin/sh
CWD=`pwd`
DOCSTRING="Usage: ./instrument-apk.sh -p PROJECTDIR -k PATH/TO/KEYSTORE -a ALIAS_FOR_SIGNING_KEY -f PATH_TO_FRIDA_LIBS"
KEYMSG="You can create a new signing key via with 'keytool -genkey -v -keystore KEYSTORE -alias KEYALIAS -keyalg RSA -keysize 2048 -validity 8192'"
REBUILD_ONLY=0
WORKDIR="$HOME/.config/frida-scripts"
LIBDIR="$WORKDIR/frida-libs"
while [ "$1" != "" ];
do
case $1 in
    -r |--rebuild-only )
    echo "REBUILD ONLY mode"
    REBUILD_ONLY=1
    ;;
    -p |--project )
    shift
    PROJECTDIR="$1"
    ;;
    -k |--keystore )
    shift
    KEYSTORE="$1"
    ;;
    -a |--keyalias )
    shift
    KEYALIAS="$1"
    ;;
    -h|--help)
    echo "$DOCSTRING"
    echo "$KEYMSG"
    exit
    ;;
    -f|--frida)
    shift
    LIBDIR="$1"
    exit
    ;;
    *)
    echo $1
    echo "$DOCSTRING"
    echo "$KEYMSG"
    exit
    ;;
esac
shift
done

if [ ! -d $PROJECTDIR ]; then
    echo "APK project directory not found! Exiting!"
    echo "$DOCSTRING"
    exit -1
fi


if [ ! -d $LIBDIR ]; then
    echo "Directory $LIBDIR for frida libs does not exist or is not a directory. Exiting."
    echo "$DOCSTRING"
    exit -11
fi

FULLPATH=`realpath $PROJECTDIR`
BASENAME=`basename $FULLPATH`


EXTRACT_DIR="$PROJECTDIR/extracted"

if [ ! -f "$EXTRACT_DIR/AndroidManifest.xml" ]; then
  echo "No extracted APK found in $EXTRACT_DIR - Exiting!"
  exit -2
fi


echo "Copying gadget libraries from $LIBDIR"
VERSION=`cat "$WORKDIR/LATEST_RELEASE"`
GADGET_LIB=libfrida-gadget.so
ARCH="arm64"
DST="$EXTRACT_DIR/lib/arm64-v8a"
FRIDA_LIB="$LIBDIR/frida-gadget-$VERSION-android-$ARCH.so"
mkdir -p "$DST"
cp "$FRIDA_LIB" "$DST"/$GADGET_LIB

ARCH="arm"
DST="$EXTRACT_DIR/lib/armeabi"
FRIDA_LIB="$LIBDIR/frida-gadget-$VERSION-android-$ARCH.so"
mkdir -p "$DST"
cp "$FRIDA_LIB" "$DST"/$GADGET_LIB
DST="$EXTRACT_DIR/lib/armeabi-v7a"
FRIDA_LIB="$LIBDIR/frida-gadget-$VERSION-android-$ARCH.so"
mkdir -p "$DST"
cp "$FRIDA_LIB" "$DST"/$GADGET_LIB


ARCH="x86"
DST="$EXTRACT_DIR/lib/x86"
FRIDA_LIB="$LIBDIR/frida-gadget-$VERSION-android-$ARCH.so"
mkdir -p "$DST"
cp "$FRIDA_LIB" "$DST"/$GADGET_LIB

ARCH="arm"
DST="$EXTRACT_DIR/lib/x86_64"
FRIDA_LIB="$LIBDIR/frida-gadget-$VERSION-android-$ARCH.so"
mkdir -p "$DST"
cp "$FRIDA_LIB" "$DST"/$GADGET_LIB


echo "Please add or update the library injection ('System.loadLibrary(\"frida-gadget\")') to the code (use another terminal window :-) )."
echo "E.g."
echo "const-string v0, \"frida-gadget\""
echo "invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V"
echo "in a static initializer."
echo
echo "Grant frida permissions to open a socket by adding "
echo "<uses-permission android:name=\"android.permission.INTERNET\" />"
echo "somewhere before the <application> tag."
echo
read -p "Press enter to continue after you have made the required changes. The script will continue to build the instrumented APK..."

TMP_APK=$PROJECTDIR/tmp-$BASENAME.apk
echo "Repackging APK into: $TMP_APK"
rm $TMP_APK
apktool b -o $TMP_APK $EXTRACT_DIR/

echo "Signing the APK. If you already have a signing key just press Enter to continue. If not create a new key via:"
echo "keytool -genkey -v -keystore $KEYSTORE -alias $KEYALIAS -keyalg RSA -keysize 2048 -validity 8192"
read -p "Press enter to continue..."

echo "Creating signature"
echo Executing: jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE $TMP_APK $KEYALIAS
jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE $TMP_APK $KEYALIAS


NEW_APK="$PROJECTDIR/instrumented-$BASENAME.apk"
echo "Checking signature"
jarsigner -verify $TMP_APK

echo "Done"


echo "Zipaligning the new APK"
rm $NEW_APK
zipalign 4 $TMP_APK $NEW_APK

echo
echo "Install with"
echo "adb install -r $NEW_APK"
