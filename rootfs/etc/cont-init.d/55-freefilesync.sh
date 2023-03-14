#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Make sure required directories exist.
mkdir -p "$XDG_DATA_HOME"

# Copy the default Firefox profile.
if [ ! -d /config/ff-profile ]; then
    cp -r /defaults/ff-profile /config/ff-profile
fi

# Clear the fstab file to make sure its content is not displayed when selecting
# folder to add.
echo > /etc/fstab
