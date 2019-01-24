#!/bin/sh
CWD=`pwd`
WORKDIR="$HOME/.config/frida-scripts"
LIBDIR="$WORKDIR/frida-libs"
echo "Creating $WORKDIR for Frida binaries"

mkdir -p "$LIBDIR"

cd "$WORKDIR"
echo `pwd`
# Get the latest version number
VERSION_FILE="$WORKDIR/tmp.json"
echo "Getting Frida version"
echo curl -s -X GET https://api.github.com/repos/frida/frida/tags -o $VERSION_FILE
curl -s -X GET https://api.github.com/repos/frida/frida/tags -o $VERSION_FILE
LATEST_RELEASE=`cat $VERSION_FILE|grep name | head -1 |  sed 's/\"//g' |  sed 's/\,//g'|  gawk '{split($0,array,": ")} END{print array[2]}'`
rm $VERSION_FILE


# Store it for the deplyment script to find the correct version
echo "Updating frida to $LATEST_RELEASE"
echo $LATEST_RELEASE > "LATEST_RELEASE"

# This depends on your preferences and how your distro/operating system names the pip binary
# Windows users will have to adjust this (if you use Pycharm you should be able to install Frida via Pycharms built-in package manager). 
sudo pip3 install frida-tools --upgrade
sudo pip2 install frida-tools --upgrade

cd "$LIBDIR"
# we are inside frida-libs - clean up older versions
rm -f frida*

# download x86/x86_64/arm/arm64 server and gadget files - just add other architectures here
curl -# -L -O -J https://github.com/frida/frida/releases/download/$LATEST_RELEASE/frida-gadget-$LATEST_RELEASE-android-x86_64.so.xz
curl -# -L -O -J https://github.com/frida/frida/releases/download/$LATEST_RELEASE/frida-gadget-$LATEST_RELEASE-android-x86.so.xz
curl -# -L -O -J https://github.com/frida/frida/releases/download/$LATEST_RELEASE/frida-gadget-$LATEST_RELEASE-android-arm64.so.xz
curl -# -L -O -J https://github.com/frida/frida/releases/download/$LATEST_RELEASE/frida-gadget-$LATEST_RELEASE-android-arm.so.xz
curl -# -L -O -J https://github.com/frida/frida/releases/download/$LATEST_RELEASE/frida-server-$LATEST_RELEASE-android-x86_64.xz
curl -# -L -O -J https://github.com/frida/frida/releases/download/$LATEST_RELEASE/frida-server-$LATEST_RELEASE-android-x86.xz
curl -# -L -O -J https://github.com/frida/frida/releases/download/$LATEST_RELEASE/frida-server-$LATEST_RELEASE-android-arm64.xz
curl -# -L -O -J https://github.com/frida/frida/releases/download/$LATEST_RELEASE/frida-server-$LATEST_RELEASE-android-arm.xz

# unpack the downloaded archives
for f in *.xz
do
  7z x "$f"
done
rm *.xz

# go back to where we started
cd "$CWD"
