#!/bin/bash -e

# Sync files and database between BLUE and GREEN sites.
# Required variables
# - MOUNT_PATH
# - IDENTITY_FILE
# - BLUE_SITE_NAME
# - BLUE_SITE_SFTP_HOST
# - BLUE_SITE_SFTP_USER
# - BLUE_SITE_SFTP_PORT
# - GREEN_SITE_NAME
# - GREEN_SITE_SFTP_HOST
# - GREEN_SITE_SFTP_USER
# - GREEN_SITE_SFTP_PORT

# Prepare variables
TMP_DIR_NAME=$(echo $RANDOM | md5sum | head -c 8)
MOUNT_PATH="$RUNNER_TEMP/files-$TMP_DIR_NAME"
mkdir $MOUNT_PATH

# Fix vars
IDENTITY_FILE=$(echo ~/.ssh/id_rsa)
BLUE_SITE_SFTP_HOST=$(echo "$BLUE_SITE_SFTP_HOST" | tr " " ".")
BLUE_SITE_SFTP_USER=$(echo "$BLUE_SITE_SFTP_USER" | tr " " ".")
GREEN_SITE_SFTP_HOST=$(echo "$GREEN_SITE_SFTP_HOST" | tr " " ".")
GREEN_SITE_SFTP_USER=$(echo "$GREEN_SITE_SFTP_USER" | tr " " ".")

# Create rclone conf file.
mkdir -p ~/.config/rclone
cat <<EOF > ~/.config/rclone/rclone.conf
[$BLUE_SITE_NAME]
type = sftp
host = $BLUE_SITE_SFTP_HOST
user = $BLUE_SITE_SFTP_USER
port = $BLUE_SITE_SFTP_PORT
path = files
key_file = $IDENTITY_FILE
use_insecure_cipher = false

[$GREEN_SITE_NAME]
host = $GREEN_SITE_SFTP_HOST
user = $GREEN_SITE_SFTP_USER
port = $GREEN_SITE_SFTP_PORT
path = files
key_file = $IDENTITY_FILE
use_insecure_cipher = false
EOF

# Debug
cat ~/.config/rclone/rclone.conf

# Mount local directory for SOURCE remote
sshfs \
-o reconnect,compression=yes,port=$BLUE_SITE_SFTP_PORT \
-o IdentityFile=$IDENTITY_FILE \
-o StrictHostKeyChecking=no \
-o ServerAliveInterval=15 \
-vvv \
$BLUE_SITE_NAME $MOUNT_PATH

# Rclone
rclone sync --progress --transfers 20 $MOUNT_PATH $GREEN_SITE_NAME

# Unmount path
fusermount -u $MOUNT_PATH
# Check if the unmount command failed
if [ $? -ne 0 ]; then
    sudo umount -lf $MOUNT_PATH
    # Check if sudo unmount failed
    if [ $? -ne 0 ]; then
        echo "umount also failed."
    else
        echo "umount succeeded."
    fi
fi
