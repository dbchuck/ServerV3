#!/bin/bash

set -x

# configure snapper
snapper -c root create-config / &
sleep 5
rm /etc/snapper/configs/root
cat << 'EOF' > /etc/snapper/configs/root
# subvolume to snapshot
SUBVOLUME="/"

# filesystem type
FSTYPE="btrfs"

# btrfs qgroup for space aware cleanup algorithms
QGROUP=""

# fraction of the filesystems space the snapshots may use
SPACE_LIMIT="0.1"

# users and groups allowed to work with config
ALLOW_USERS=""
ALLOW_GROUPS=""

# sync users and groups from ALLOW_USERS and ALLOW_GROUPS to .snapshots
# directory
SYNC_ACL="no"

# start comparing pre- and post-snapshot in background after creating
# post-snapshot
BACKGROUND_COMPARISON="yes"

# run daily number cleanup
NUMBER_CLEANUP="yes"

# limit for number cleanup
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="6"
NUMBER_LIMIT_IMPORTANT="0"

# create hourly snapshots
TIMELINE_CREATE="yes"

# cleanup hourly snapshots after some time
TIMELINE_CLEANUP="yes"

# limits for timeline cleanup
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="3"
TIMELINE_LIMIT_DAILY="3"
TIMELINE_LIMIT_WEEKLY="3"
TIMELINE_LIMIT_MONTHLY="5"
TIMELINE_LIMIT_YEARLY="5"

# cleanup empty pre-post-pairs
EMPTY_PRE_POST_CLEANUP="yes"

# limits for empty pre-post-pair cleanup
EMPTY_PRE_POST_MIN_AGE="1800"
EOF

systemctl enable --now snapper-cleanup.timer
systemctl enable --now snapper-cleanup.service
systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-timeline.service
