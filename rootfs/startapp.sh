#!/bin/sh

# Needed for Firefox.
export HOME=/config

# For GTK3 freeze : https://freefilesync.org/forum/viewtopic.php?t=10103
export GDK_SYNCHRONIZE=1

cd /storage
exec /opt/FreeFileSync/Bin/FreeFileSync
