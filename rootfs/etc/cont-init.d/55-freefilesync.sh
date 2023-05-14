#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Make sure required directories exist.
mkdir -p \
    "$XDG_DATA_HOME" \
    "$XDG_CONFIG_HOME"/FreeFileSync \
    "$XDG_CONFIG_HOME"/gtk-3.0 \

# Copt default files.
[ -f /config/xdg/config/gtk-3.0/bookmarks ] || cp /defaults/bookmarks /config/xdg/config/gtk-3.0/bookmarks
[ -f "$XDG_CONFIG_HOME"/FreeFileSync/LastRun.ffs_gui ] || cp /defaults/LastRun.ffs_gui "$XDG_CONFIG_HOME"/FreeFileSync/LastRun.ffs_gui

# Copy the default Firefox profile.
if [ ! -d /config/ff-profile ]; then
    cp -r /defaults/ff-profile /config/ff-profile
fi

# Clear the fstab file to make sure its content is not displayed when selecting
# folder to add.
echo > /etc/fstab
