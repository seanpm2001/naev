#!/bin/bash

# AppImage BUILD SCRIPT FOR NAEV
#
# Written by Jack Greiner (ProjectSynchro on Github: https://github.com/ProjectSynchro/)
#
# For more information, see http://appimage.org/
# Pass in [-d] [-n] (set this for nightly builds) -s <SOURCEROOT> (Sets location of source) -b <BUILDROOT> (Sets location of build directory) -o <BUILDOUTPUT> (Dist output directory)

# All outputs will be within pwd if nothing is passed in

set -e

# Defaults
SOURCEROOT="$(pwd)"
BUILDPATH="$(pwd)/build/appimageBuild"
NIGHTLY="false"
BUILDOUTPUT="$(pwd)/dist"

while getopts dns:b:o: OPTION "$@"; do
    case $OPTION in
    d)
        set -x
        ;;
    n)
        NIGHTLY="true"
        ;;
    s)
        SOURCEROOT="${OPTARG}"
        ;;
    b)
        BUILDPATH="${OPTARG}"
        ;;
    o)
        BUILDOUTPUT="${OPTARG}"
        ;;
    esac
done

BUILD_DATE="$(date +%Y%m%d)"

# Honours the MESON variable set by the environment before setting it manually.

if [ -z "$MESON" ]; then
    MESON="$SOURCEROOT/meson.sh"
fi


# Output configured variables

echo "SOURCE ROOT:        $SOURCEROOT"
echo "BUILD ROOT:         $BUILDPATH"
echo "NIGHTLY:            $NIGHTLY"
echo "BUILD OUTPUT:       $BUILDOUTPUT"
echo "MESON WRAPPER PATH: $MESON"

# Set DESTDIR

OLDDISTDIR="$DISTDIR"
unset DESTDIR
export DESTDIR="$BUILDOUTPUT/Naev.AppDir"

# Setup AppImage Build Directory

sh "$MESON" setup "$BUILDPATH" "$SOURCEROOT" \
    --native-file "$SOURCEROOT/utils/build/linux_appimage.ini" \
    --buildtype release \
    -Db_lto=true \
    -Dauto_features=enabled \
    -Ddocs_c=disabled \
    -Ddocs_lua=disabled

# Compile and Install Naev to DISTDIR

sh "$MESON" install -C "$BUILDPATH"

# Prep dist directory for appimage
# (I hate this but otherwise linuxdeploy fails on systems that generate the desktop file)

rm "$DESTDIR"/usr/share/applications/*.desktop
cp "$SOURCEROOT/org.naev.naev.desktop" "$DESTDIR/usr/share/applications/"

# Set ARCH of AppImage
export ARCH=$(arch)

# Set VERSION and OUTPUT variables
if [ -f "$SOURCEROOT/dat/VERSION" ]; then
    export VERSION="$(<"$SOURCEROOT/dat/VERSION")"
else
    echo "The VERSION file is missing from $SOURCEROOT."
    exit -1
fi
if [[ "$NIGHTLY" == "true" ]]; then
    export VERSION="$VERSION.$BUILD_DATE"
fi

# Make output dir (if it does not exist)
mkdir -p $BUILDOUTPUT/out

export OUTPUT="$BUILDOUTPUT/out/naev-$VERSION-lin64.AppImage"

# Get linuxdeploy's AppImage
linuxdeploy="$BUILDPATH/linuxdeploy-x86_64.AppImage"
if [ ! -f "$linuxdeploy" ]; then
    wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage \
        -O "$linuxdeploy"
    chmod +x "$linuxdeploy"
fi

# Run linuxdeploy and generate an AppDir, then generate an AppImage

"$linuxdeploy" \
    --appdir "$DESTDIR" \
    --output appimage

# Move AppImage to dist/ and mark as executable

chmod +x $OUTPUT

#Reset DESTDIR to what it was before

unset DESTDIR
export DESTDIR="$OLDDISTDIR"
