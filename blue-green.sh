#!/bin/bash -e

#   ____  _               ______                     
#  | __ )| |_   _  ___   / / ___|_ __ ___  ___ _ __  
#  |  _ \| | | | |/ _ \ / / |  _| '__/ _ \/ _ \ '_ \ 
#  | |_) | | |_| |  __// /| |_| | | |  __/  __/ | | |
#  |____/|_|\__,_|\___/_/  \____|_|  \___|\___|_| |_|
#
# Blue / Green deployment script for Pantheon sites using Terminus. 
#
# Example usage
# ./blue-green.sh site-id-1.src_env site-id-2.dest_env
# 
# Required dependencies:
# - jq
# - sshfs
# - rclone
# - terminus
#
# Required information:
# - Pantheon Machine Token
# - SSH key (in PEM format)
# - Source site ID
# - Destination site ID
#
# This script will attempt the following in a CI environment:
# 1. Fetch site information (Git URL, SFTP and MySQL connections, backups)
#
# 2. Create a copy of the Site Git repository, sync the git commits from source to destination
#  2.1 We clone the DESTINATION site repository.
#  2.2 We add the SOURCE site as a git remote to the DESTINATION git repo.
#  2.3 Then we merge the SOURCE commits into the DESTINATION repo.
#  2.4 Finally, we push the updated commits to the DESTINATION origin.
#
# 3. Sync files between source and destination using SSHFS and rclone
#  3.1 SSHFS is a FUSE package that allows us to mount remote systems as local directories.
#  3.2 Rclone is a performant alternative to rsync and increases the file transfer concurrency.
#  3.3 We mount the SOURCE remote files directory as a local directory using SSHFS.
#  3.4 Then we `rclone sync` the "local" directory to the remote DESTINATION files directory.
#  3.5 This allows us to essentially run a remote-to-remote sync process without handling large archives.
#
# 4. Sync database between source and destination.
#  4.1 Export only a copy of the source database.
#  4.2 Import the database archive into the destination.
#
# 5. Enable maintenance mode on source, redirecting traffic to destination.


# Prepare some variables.
TMP_DIR_NAME=$(echo $RANDOM | md5sum | head -c 8)
TMP_DIR_PATH="/tmp/$TMP_DIR_NAME"
MOUNT_PATH="/tmp/files-$TMP_DIR_NAME"
IFS='.'
# Replace with path to key if different.
IDENTITY_FILE=$(echo ~/.ssh/id_rsa)

# Create temporary directory for workspace.
mkdir $TMP_DIR_PATH
cd $TMP_DIR_PATH

# Prepare site information
BLUE_SITE=$1
GREEN_SITE=$2
read -ra BLUE_PARTS <<< "$BLUE_SITE"
read -ra GREEN_PARTS <<< "$GREEN_SITE"

# Ensure we have enough properties.
if [ -z "$BLUE_PARTS[1]" ] || [ -z "$GREEN_PARTS[1]" ]; then
    echo 'There are not enough site IDs or environments defined.' >&2
    exit 1
fi

# Declare BLUE site variables.
BLUE_SITE_NAME=$(echo "${BLUE_PARTS[0]}")
BLUE_SITE_ENV=$(echo "${BLUE_PARTS[1]}")
BLUE_SITE_INFO=$(terminus connection:info ${BLUE_SITE_NAME}.${BLUE_SITE_ENV} --fields sftp_username,sftp_host,git_url --format json)
BLUE_SITE_REPO=$(echo $BLUE_SITE_INFO | jq -r '.git_url')
BLUE_SITE_SFTP_USER=$(echo $BLUE_SITE_INFO | jq -r '.sftp_username')
BLUE_SITE_SFTP_HOST=$(echo $BLUE_SITE_INFO | jq -r '.sftp_host')
BLUE_SITE_SFTP_PORT='2222'

# Declare GREEN site variables.
GREEN_SITE_NAME=$(echo "${GREEN_PARTS[0]}")
GREEN_SITE_ENV=$(echo "${GREEN_PARTS[1]}")
GREEN_SITE_INFO=$(terminus connection:info ${GREEN_SITE_NAME}.${GREEN_SITE_ENV} --fields sftp_username,sftp_host,git_url --format json)
GREEN_SITE_REPO=$(echo $GREEN_SITE_INFO | jq -r '.git_url')
GREEN_SITE_SFTP_USER=$(echo $GREEN_SITE_INFO | jq -r '.sftp_username')
GREEN_SITE_SFTP_HOST=$(echo $GREEN_SITE_INFO | jq -r '.sftp_host')
GREEN_SITE_SFTP_PORT='2222'

# Establish base branch for Pantheon site syncing.
BASE_BRANCH='master'

#################################
# Merge code from GREEN into BLUE
#################################

# Prepare git credentials
FNAME=$(terminus auth:whoami --field firstname)
LNAME=$(terminus auth:whoami --field lastname)
GIT_EMAIL=$(terminus auth:whoami --field email)
GIT_NAME="$FNAME $LNAME"

# Configure git defaults
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_NAME"
git config pull.rebase false

# Setup repo, add remote branch connection, sync code.
git clone $GREEN_GIT_REPO $GREEN_SITE_NAME && cd $GREEN_SITE_NAME
git remote add $BLUE_SITE_NAME $BLUE_GIT_REPO

# Check if remote branch exists
_check_branch=$(git ls-remote --heads $BLUE_SITE_NAME $BASE_BRANCH)
[[ -n ${_check_branch} ]] && git pull $BLUE_SITE_NAME $BASE_BRANCH --rebase
# Sync branch
git push -u $GREEN_SITE_NAME HEAD:refs/heads/$BASE_BRANCH

# Wrap all file sync commands together.
function sync_files {

    # Sync files and database between BLUE and GREEN sites.
    mkdir $MOUNT_PATH

    # Create rclone conf file.
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

    # Mount local directory for SOURCE remote
    sshfs \
    -o reconnect,compression=yes,port=$BLUE_SITE_SFTP_PORT \
    -o IdentityFile=$IDENTITY_FILE \
    -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=15 \
    $BLUE_SITE \ # Source remote config in rclone
    $MOUNT_PATH  # Local directory path

    # Rclone
    rclone sync \
    --progress \ 
    --transfers 20 \
    $MOUNT_PATH \    # Local mounted directory for Source
    $GREEN_SITE # Destination remote

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
}

# Wrap database functions together.
function sync_database {
    terminus backup:create $BLUE_SITE --element=db
    BLUE_SITE_DB_URL=$(terminus backup:get ${BLUE_SITE} --element=db)
    terminus import:database $GREEN_SITE $BLUE_SITE_DB_URL -y
}

# Run file sync and database import in parallel.
nohup sync_files &
nohup sync_database &
wait

# Switch traffic between sites.
# Ensure GREEN site is not in maintenance mode.
terminus drush $GREEN_SITE vset --yes maintenance_mode 0;
terminus drush $GREEN_SITE cc all;

# Enable maintenance mode on BLUE to redirect traffic to GREEN.
terminus drush $BLUE_SITE vset --yes maintenance_mode 1;
terminus drush $BLUE_SITE cc all;