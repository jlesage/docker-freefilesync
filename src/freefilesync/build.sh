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
LIBSSH2_URL="${3:-}"
CURL_URL="${4:-}"
GOOGLE_CLIENT_ID_K1="${5:-}"
GOOGLE_CLIENT_ID_K2="${6:-}"
GOOGLE_CLIENT_SECRET_K1="${7:-}"
GOOGLE_CLIENT_SECRET_K2="${8:-}"

if [ -z "$FREEFILESYNC_URL" ]; then
    log "ERROR: FreeFileSync URL missing."
    exit 1
fi

if [ -z "$WXWIDGETS_URL" ]; then
    log "ERROR: wxWidgets URL missing."
    exit 1
fi

if [ -z "$LIBSSH2_URL" ]; then
    log "ERROR: libssh2 URL missing."
    exit 1
fi

if [ -z "$CURL_URL" ]; then
    log "ERROR: curl URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    curl \
    git \
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
    gtk+3.0-dev \
    libsm-dev \
    zlib-dev \
    brotli-dev \
    c-ares-dev \
    libidn2-dev \
    libpsl-dev \
    nghttp2-dev \
    openssl-dev \
    zstd-dev \

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
    TRIES="$(expr "$TRIES" - 1)"
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
if [ -n "${WXWIDGETS_URL##*@}" ]; then
    git clone "${WXWIDGETS_URL%%@*}" /tmp/wxwidgets
    git -C /tmp/wxwidgets reset --hard "${WXWIDGETS_URL##*@}"
    git -C /tmp/wxwidgets submodule update --init
else
    mkdir /tmp/wxwidgets
    curl -# -L -f "${WXWIDGETS_URL}" | tar xz --strip 1 -C /tmp/wxwidgets
fi

log "Download libssh2 package..."
mkdir /tmp/libssh2
curl -# -L -f "${LIBSSH2_URL}" | tar xz --strip 1 -C /tmp/libssh2

log "Download curl package..."
mkdir /tmp/curl
curl -# -L -f "${CURL_URL}" | tar xJ --strip 1 -C /tmp/curl

#
# Compile wxWidgets.
#

log "Patching libssh2..."
PATCHES="
    wxwidgets-bug-fixes.patch
"
for PATCH in $PATCHES; do
    log "Applying $PATCH..."
    patch -p1 -d /tmp/wxwidgets < "$SCRIPT_DIR"/"$PATCH"
done

log "Configuring wxWidgets..."
(
    cd /tmp/wxwidgets && ./configure \
        --build=$(TARGETPLATFORM= xx-info) \
        --host=$(xx-info) \
        --prefix=$(xx-info sysroot)usr \
        --disable-shared \
        --disable-xlocale \
        --disable-exceptions \
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
# Compile libssh2.
#

log "Patching libssh2..."
PATCHES="
    libssh2-bug-fixes.patch
"
for PATCH in $PATCHES; do
    log "Applying $PATCH..."
    patch -p1 -d /tmp/libssh2 < "$SCRIPT_DIR"/"$PATCH"
done

log "Configuring libssh2..."
(
    cd /tmp/libssh2 && ./configure \
        --build=$(TARGETPLATFORM= xx-info) \
        --host=$(xx-info) \
        --prefix=$(xx-info sysroot)usr \
        --disable-shared \
        --with-crypto=openssl \
)

log "Compiling libssh2..."
make -C /tmp/libssh2 -j$(nproc)

log "Installing libssh2..."
make -C /tmp/libssh2 install

#
# Compile curl.
#

log "Patching curl..."
PATCHES="
    curl-bug-fixes.patch
"
for PATCH in $PATCHES; do
    log "Applying $PATCH..."
    patch -p1 -d /tmp/curl < "$SCRIPT_DIR"/"$PATCH"
done

log "Configuring curl..."
(
    cd /tmp/curl && ./configure \
        --build=$(TARGETPLATFORM= xx-info) \
        --host=$(xx-info) \
        --prefix=$(xx-info sysroot)usr \
        --disable-docs \
        --disable-shared \
        --enable-static \
        --enable-ares \
        --enable-ipv6 \
        --enable-unix-sockets \
        --with-libidn2 \
        --with-nghttp2 \
        --with-openssl \
        --with-ca-bundle=/etc/ssl/cert.pem \
        --disable-ldap \
        --with-pic \
        --enable-websockets \
        --without-libssh2 \
)

log "Compiling curl..."
make -C /tmp/curl -j$(nproc)

log "Installing curl..."
make -C /tmp/curl install

#
# Compile FreeFileSync.
#

log "Patching FreeFileSync..."
PATCHES="
    compilation-fix.patch
    client-credentials.patch
    default-deletion-policy.patch
    default-auto-close.patch
    disable-update.patch
    disable-open-with-default-app.patch
    fix-hang.patch
    disable-getentropy.patch
    disable-minimize-to-tray.patch
    disable-color-theme.patch
"
for PATCH in $PATCHES; do
    log "Applying $PATCH..."
    patch -p1 -d /tmp/freefilesync < "$SCRIPT_DIR"/"$PATCH"
done

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
