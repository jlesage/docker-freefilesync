#
# freefilesync Dockerfile
#
# https://github.com/jlesage/docker-freefilesync
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG FREEFILESYNC_VERSION=13.6
ARG WXWIDGETS_VERSION=3.2.4
ARG LIBSSH2_VERSION=1.11.0

# Define software download URLs.
ARG FREEFILESYNC_URL=https://freefilesync.org/download/FreeFileSync_${FREEFILESYNC_VERSION}_Source.zip
ARG WXWIDGETS_URL=https://github.com/wxWidgets/wxWidgets/releases/download/v${WXWIDGETS_VERSION}/wxWidgets-${WXWIDGETS_VERSION}.tar.bz2
ARG LIBSSH2_URL=http://www.libssh2.org/download/libssh2-${LIBSSH2_VERSION}.tar.gz

# Google API client ID and secret to enable Sign-in with Google.
ARG GOOGLE_CLIENT_ID_K1=
ARG GOOGLE_CLIENT_ID_K2=
ARG GOOGLE_CLIENT_SECRET_K1=
ARG GOOGLE_CLIENT_SECRET_K2=

# Get Dockerfile cross-compilation helpers.
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

# Build FreeFileSync.
FROM --platform=$BUILDPLATFORM alpine:3.17 AS freefilesync
ARG TARGETPLATFORM
ARG FREEFILESYNC_URL
ARG WXWIDGETS_URL
ARG LIBSSH2_URL
ARG GOOGLE_CLIENT_ID_K1
ARG GOOGLE_CLIENT_ID_K2
ARG GOOGLE_CLIENT_SECRET_K1
ARG GOOGLE_CLIENT_SECRET_K2
COPY --from=xx / /
COPY src/freefilesync /build
RUN /build/build.sh \
    "$FREEFILESYNC_URL" \
    "$WXWIDGETS_URL" \
    "$LIBSSH2_URL" \
    "$GOOGLE_CLIENT_ID_K1" \
    "$GOOGLE_CLIENT_ID_K2" \
    "$GOOGLE_CLIENT_SECRET_K1" \
    "$GOOGLE_CLIENT_SECRET_K2"
RUN xx-verify /tmp/freefilesync/FreeFileSync/Build/Bin/FreeFileSync

# Pull base image.

FROM jlesage/baseimage-gui:alpine-3.17-v4.6.3

ARG FREEFILESYNC_VERSION
ARG DOCKER_IMAGE_VERSION

# Define working directory.
WORKDIR /tmp

# Install dependencies.
RUN \
    add-pkg \
        gtk+3.0 \
        libcurl \
        libsm \
        libxxf86vm \
        librsvg \
        font-cantarell \
        adwaita-icon-theme \
        supercronic \
        pcmanfm \
        firefox-esr

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/freefilesync-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /
COPY --from=freefilesync /tmp/freefilesync/FreeFileSync/Build /opt/FreeFileSync

# Set environment variables.
ENV APP_NAME="FreeFileSync"

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "FreeFileSync" && \
    set-cont-env APP_VERSION "$FREEFILESYNC_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

# Define mountable directories.
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="freefilesync" \
      org.label-schema.description="Docker container for FreeFileSync" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-unknown}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-freefilesync" \
      org.label-schema.schema-version="1.0"
