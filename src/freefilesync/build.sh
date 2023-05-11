#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

export CFLAGS="--sysroot=$(xx-info sysroot)"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="--sysroot=$(xx-info sysroot)"

if xx-info is-cross; then
    export CC=$(xx-info)-gcc
    export CXX=$(xx-info)-g++
else
    export CC=gcc
    export CXX=g++
fi

export PKG_CONFIG_SYSROOT_DIR=$(xx-info sysroot)
export PKG_CONFIG_LIBDIR=$(xx-info sysroot)usr/lib/pkgconfig/
# shared-mime-info.pc is installed under /usr/share/pkgconfig.
export PKG_CONFIG_PATH=$(xx-info sysroot)usr/share/pkgconfig

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

function log {
    echo ">>> $*"
}

FREEFILESYNC_URL="${1:-}"
WXWIDGETS_URL="${2:-}"
GOOGLE_CLIENT_ID_K1="${3:-}"
GOOGLE_CLIENT_ID_K2="${4:-}"
GOOGLE_CLIENT_SECRET_K1="${5:-}"
GOOGLE_CLIENT_SECRET_K2="${6:-}"

if [ -z "$FREEFILESYNC_URL" ]; then
    log "ERROR: FreeFileSync URL missing."
    exit 1
fi

if [ -z "$WXWIDGETS_URL" ]; then
    log "ERROR: wxWidgets URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    curl \
    patch \
    make \
    pkgconf \

if xx-info is-cross; then
    apk --no-cache --allow-untrusted --repository http://mirror.postmarketos.org/postmarketos/v22.12 add \
        binutils-$(xx-info alpine-arch) \
        g++-$(xx-info alpine-arch) \
        musl-dev-$(xx-info alpine-arch)
else
    apk --no-cache add \
        gcc \
        g++
fi

xx-apk --no-cache --no-scripts add \
    openssl-dev \
    libssh2-dev \
    curl-dev \
    gtk+3.0-dev \
    libsm-dev \
    zlib-dev \

#
# Download sources.
#

log "Downloading FreeFileSync package..."
mkdir /tmp/freefilesync
TRIES=5
while [ "$TRIES" -gt 0 ];
do
    if curl -# -L -f -o /tmp/freefilesync.zip "${FREEFILESYNC_URL}" && [ "$(stat -c "%s" /tmp/freefilesync.zip)" -gt 2097152 ]
    then
        # File downloaded correctly.
        break
    fi

    # Try again
    echo "Failed to download FreeFileSync, retrying..."
    rm -f /tmp/freefilesync.zip
    sleep 5
done
if [ ! -f /tmp/freefilesync.zip ]; then
    "ERROR: Failed to download FreeFileSync."
    exit 1
fi
unzip -d /tmp/freefilesync /tmp/freefilesync.zip

log "Download wxWidgets package..."
mkdir /tmp/wxwidgets
curl -# -L -f "${WXWIDGETS_URL}" | tar xj --strip 1 -C /tmp/wxwidgets

#
# Compile wxWidgets.
#

log "Configuring wxWidgets..."
(
    cd /tmp/wxwidgets && ./configure \
        --build=$(TARGETPLATFORM= xx-info) \
        --host=$(xx-info) \
        --prefix=$(xx-info sysroot)usr \
        --disable-shared \
        --enable-unicode \
        --disable-xlocale \
        --with-gtk=3 \
)

log "Compiling wxWidgets..."
make -C /tmp/wxwidgets -j$(nproc)

log "Installing wxWidgets..."
make -C /tmp/wxwidgets install
if xx-info is-cross; then
    ln -s $(xx-info sysroot)usr/bin/wx-config /usr/bin/wx-config
fi

#
# Compile FreeFileSync.
#

export CFLAGS="$CFLAGS -DMAX_SFTP_READ_SIZE=30000 -DMAX_SFTP_OUTGOING_SIZE=30000"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"

log "Patching FreeFileSync..."
patch -p1 -d /tmp/freefilesync < "$SCRIPT_DIR"/compilation-fix.patch
patch -p1 -d /tmp/freefilesync < "$SCRIPT_DIR"/disable-update.patch
patch -p1 -d /tmp/freefilesync < "$SCRIPT_DIR"/client-credentials.patch
patch -p1 -d /tmp/freefilesync < "$SCRIPT_DIR"/disable-open-with-default-app.patch

sed -i "s/GDRIVE_CLIENT_ID_K1\[\] = {}/GDRIVE_CLIENT_ID_K1\[\] = {${GOOGLE_CLIENT_ID_K1}}/" /tmp/freefilesync/FreeFileSync/Source/afs/gdrive.cpp
sed -i "s/GDRIVE_CLIENT_ID_K2\[\] = {}/GDRIVE_CLIENT_ID_K2\[\] = {${GOOGLE_CLIENT_ID_K2}}/" /tmp/freefilesync/FreeFileSync/Source/afs/gdrive.cpp
sed -i "s/GDRIVE_CLIENT_SECRET_K1\[\] = {}/GDRIVE_CLIENT_SECRET_K1\[\] = {${GOOGLE_CLIENT_SECRET_K1}}/" /tmp/freefilesync/FreeFileSync/Source/afs/gdrive.cpp
sed -i "s/GDRIVE_CLIENT_SECRET_K2\[\] = {}/GDRIVE_CLIENT_SECRET_K2\[\] = {${GOOGLE_CLIENT_SECRET_K2}}/" /tmp/freefilesync/FreeFileSync/Source/afs/gdrive.cpp

# Fix sysroot for includes.
sed -i "s|CXXFLAGS  += -isystem/usr/include/|CXXFLAGS  += -isystem$(xx-info sysroot)usr/include/|" /tmp/freefilesync/FreeFileSync/Source/Makefile

# Use GTK 3.
sed -i "s/gtk+-2.0/gtk+-3.0/" /tmp/freefilesync/FreeFileSync/Source/Makefile
sed -i "s/gtk-2.0/gtk-3.0/" /tmp/freefilesync/FreeFileSync/Source/Makefile

log "Compiling FreeFileSync..."

#export WXDEBUG=1
make -C /tmp/freefilesync/FreeFileSync/Source -j$(nproc)
mv -v /tmp/freefilesync/FreeFileSync/Build/Bin/FreeFileSync_* /tmp/freefilesync/FreeFileSync/Build/Bin/FreeFileSync
if xx-info is-cross; then
    $(xx-info)-strip /tmp/freefilesync/FreeFileSync/Build/Bin/FreeFileSync
else
    strip /tmp/freefilesync/FreeFileSync/Build/Bin/FreeFileSync
fi
