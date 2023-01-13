#!/bin/bash -e

# Sync files and database between BLUE and GREEN sites.
# Required variables
# - MOUNT_PATH
# - IDENTITY_FILE
# - BLUE_SITE_ID
# - BLUE_SITE_SFTP_HOST
# - BLUE_SITE_SFTP_USER
# - BLUE_SITE_SFTP_PORT
# - GREEN_SITE_ID
# - GREEN_SITE_SFTP_HOST
# - GREEN_SITE_SFTP_USER
# - GREEN_SITE_SFTP_PORT

# Prepare variables
TMP_DIR_NAME=$(echo $RANDOM | md5sum | head -c 8)
MOUNT_PATH="$RUNNER_TEMP/files-$TMP_DIR_NAME"
mkdir -p $MOUNT_PATH

# Fix vars
IDENTITY_FILE=$(echo ~/.ssh/id_rsa)
BLUE_SITE_SFTP_HOST=$(echo "$BLUE_SITE_SFTP_HOST" | tr " " ".")
BLUE_SITE_SFTP_USER=$(echo "$BLUE_SITE_SFTP_USER" | tr " " ".")
GREEN_SITE_SFTP_HOST=$(echo "$GREEN_SITE_SFTP_HOST" | tr " " ".")
GREEN_SITE_SFTP_USER=$(echo "$GREEN_SITE_SFTP_USER" | tr " " ".")
BLUE_SITE_SFTP_PATH=$(echo "$BLUE_SITE_SFTP_USER@$BLUE_SITE_SFTP_HOST:files/")
GREEN_SITE_SFTP_PATH=$(echo "$GREEN_SITE_SFTP_USER@$GREEN_SITE_SFTP_HOST:files/")

# Create rclone conf file.
mkdir -p ~/.config/rclone
cat <<EOF > ~/.config/rclone/rclone.conf
[$BLUE_SITE_ID]
type = sftp
host = $BLUE_SITE_SFTP_HOST
user = $BLUE_SITE_SFTP_USER
port = $BLUE_SITE_SFTP_PORT
path = files
key_file = $IDENTITY_FILE
use_insecure_cipher = false

[$GREEN_SITE_ID]
host = $GREEN_SITE_SFTP_HOST
user = $GREEN_SITE_SFTP_USER
port = $GREEN_SITE_SFTP_PORT
path = files
key_file = $IDENTITY_FILE
use_insecure_cipher = false
EOF

# Allow non-root users to mount
echo 'user_allow_other' | sudo tee -a /etc/fuse.conf

# Mount local directory for SOURCE remote
sudo sshfs \
-o auto_cache,no_readahead,allow_other,reconnect,compression=yes \
-o port=$BLUE_SITE_SFTP_PORT \
-o IdentityFile=$IDENTITY_FILE \
-o StrictHostKeyChecking=no \
-o ServerAliveInterval=15 \
-C \
$BLUE_SITE_SFTP_PATH $MOUNT_PATH

# sudo rclone mount $BLUE_SITE_ID $MOUNT_PATH -vvv --allow-other &
# sleep 10

# Debug
echo "LIST default \n"
ls -la $MOUNT_PATH

# Rclone
sudo rclone sync --transfers 10 --retries 10 --retries-sleep 60s --progress $MOUNT_PATH $GREEN_SITE_ID

# No need to unmount, container will be reaped.