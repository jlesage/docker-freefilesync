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

is_predefined_cron_exp() {
    case "$1" in
        @annually|@yearly|@monthly|@weekly|@daily|@hourly)
            return 0
            ;;
        *)
            return 1
    esac
}

# Generate the cron file for scheduled batch jobs.
echo "# m h dom mon dow command" > /tmp/ffs_batch_jobs.cron
for ID in $(env | sed -nr 's/FFS_SCHEDULED_BATCH_JOB_([0-9]+)_NAME=.*/\1/p')
do
    eval "JOB_NAME=\"\${FFS_SCHEDULED_BATCH_JOB_${ID}_NAME:-}\""
    eval "JOB_CRON=\"\${FFS_SCHEDULED_BATCH_JOB_${ID}_CRON:-}\""
    eval "JOB_CMD=\"\${FFS_SCHEDULED_BATCH_JOB_${ID}_CMD:-}\""

    if [ -z "$JOB_NAME" ]; then
        echo "ERROR: FFS_SCHEDULED_BATCH_JOB_${ID}_NAME environment variable has no value."
        continue
    elif [ ! -f /config/"$JOB_NAME".ffs_batch ]; then
        echo "ERROR: FreeFileSync batch file '/config/"$JOB_NAME".ffs_batch' not found."
        # Continue.  The user might add the file later.
    fi

    if [ -z "$JOB_CRON" ]; then
        echo "ERROR: FFS_SCHEDULED_BATCH_JOB_${ID}_CRON environment variable has no value."
        continue
    elif ! is_predefined_cron_exp "$JOB_CRON"; then
        if [ "$(echo "$JOB_CRON" | tr -s ' ' | tr ' ' '\n' | wc -l)" -ne 5 ]; then
            echo "ERROR: FFS_SCHEDULED_BATCH_JOB_${ID}_CRON environment variable has an invalid cron format: '$JOB_CRON'."
            continue
        elif [ -n "$(echo "$JOB_CRON" | sed 's/[0-9, LW*\/\-]//g')" ]; then
            echo "ERROR: FFS_SCHEDULED_BATCH_JOB_${ID}_CRON environment variable has an invalid cron format: '$JOB_CRON'."
            continue
        fi
    fi

    if [ -n "$JOB_CMD" ]; then
        echo "$JOB_CRON /opt/FreeFileSync/Bin/FreeFileSync /config/$JOB_NAME.ffs_batch && $JOB_CMD" >> /tmp/ffs_batch_jobs.cron
    else
        echo "$JOB_CRON /opt/FreeFileSync/Bin/FreeFileSync /config/$JOB_NAME.ffs_batch" >> /tmp/ffs_batch_jobs.cron
    fi
done
