#!/bin/sh

# Needed for Firefox.
export HOME=/config

cd /config

# NOTE: Force starting with the `LastRun` profile.  Else, starting with an other
#       profile changes the title of the window to the path of the profile,
#       which cause problem to apply the correct Openbox settings.
exec /opt/FreeFileSync/Bin/FreeFileSync "$XDG_CONFIG_HOME"/FreeFileSync/LastRun.ffs_gui
