ENV_1="dev"
SITE_1="c979a373-fe44-4901-832a-8d39aaa85524"
RSYNC_1=$(echo "$ENV_1.$SITE_1@appserver.$ENV_1.$SITE_1.drush.in:files/")
RSYNC_1_NAME="$ENV_1-$SITE_1"
RSYNC_1_USER=$(echo "$ENV_1.$SITE_1")
RSYNC_1_HOST=$(echo "appserver.$ENV_1.$SITE_1.drush.in")
RSYNC_1_PORT="2222"
RSYNC_1_DIR="/files"

ENV_2="gchat"
SITE_2="c979a373-fe44-4901-832a-8d39aaa85524"
RSYNC_2="$ENV_2.$SITE_2@appserver.$ENV_2.$SITE_2.drush.in:files/"
RSYNC_2_NAME="$ENV_2-$SITE_2"
RSYNC_2_USER=$(echo "$ENV_2.$SITE_2")
RSYNC_2_HOST=$(echo "appserver.$ENV_2.$SITE_2.drush.in")
RSYNC_2_PORT="2222"
RSYNC_2_DIR="/files"

# Make sure local path directory is created to mount to
TMP_DIR_NAME=$(echo $RANDOM | md5sum | head -c 8)
MOUNT_PATH="/tmp/files-$TMP_DIR_NAME"
IDENTITY_FILE=$(echo ~/.ssh/id_rsa)
mkdir $MOUNT_PATH

# Create rclone conf file.
cat <<EOF > ~/.config/rclone/rclone.conf
[$RSYNC_1_NAME]
type = sftp
host = $RSYNC_1_HOST
user = $RSYNC_1_USER
port = $RSYNC_1_PORT
path = $RSYNC_1_DIR
key_file = $IDENTITY_FILE
use_insecure_cipher = false

[$RSYNC_2_NAME]
host = $RSYNC_2_HOST
user = $RSYNC_2_USER
port = $RSYNC_2_PORT
path = $RSYNC_2_DIR
key_file = $IDENTITY_FILE
use_insecure_cipher = false
EOF


sshfs \
-o reconnect,compression=yes,port=2222 \
-o IdentityFile=~/.ssh/id_rsa \
-o StrictHostKeyChecking=no \
-o ServerAliveInterval=15 \
$RSYNC_1 $MOUNT_PATH

# rclone mount $RSYNC_1_NAME $MOUNT_PATH -vvv --vfs-cache-mode=minimal

echo "mounted!"
# Sync files
# rsync \
# --ignore-existing \
# -rLvz --size-only --ipv4 --progress --partial \
# -e "ssh -p 2222 -i $IDENTITY_FILE -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
# $MOUNT_PATH/* $RSYNC_2

# Rclone
rclone sync --progress --transfers 20 -v $MOUNT_PATH $RSYNC_2_NAME

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