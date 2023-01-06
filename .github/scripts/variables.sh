
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
BLUE_SITE=$PANTHEON_BLUE_SITE_ENV
GREEN_SITE=$PANTHEON_GREEN_SITE_ENV
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

# Mapping all variables to Github output.
echo "IDENTITY_FILE=$(echo $IDENTITY_FILE)" >> $GITHUB_OUTPUT
echo "BASE_BRANCH=$(echo $BASE_BRANCH)" >> $GITHUB_OUTPUT
echo "TMP_DIR_NAME=$(echo $TMP_DIR_NAME)" >> $GITHUB_OUTPUT
echo "TMP_DIR_PATH=$(echo $TMP_DIR_PATH)" >> $GITHUB_OUTPUT
echo "MOUNT_PATH=$(echo $MOUNT_PATH)" >> $GITHUB_OUTPUT
echo "BLUE_SITE=$(echo $BLUE_SITE)" >> $GITHUB_OUTPUT
echo "BLUE_SITE_NAME=$(echo $BLUE_SITE_NAME)" >> $GITHUB_OUTPUT
echo "BLUE_SITE_ENV=$(echo $BLUE_SITE_ENV)" >> $GITHUB_OUTPUT
echo "BLUE_SITE_REPO=$(echo $BLUE_SITE_REPO)" >> $GITHUB_OUTPUT
echo "BLUE_SITE_SFTP_USER=$(echo $BLUE_SITE_SFTP_USER)" >> $GITHUB_OUTPUT
echo "BLUE_SITE_SFTP_HOST=$(echo $BLUE_SITE_SFTP_HOST)" >> $GITHUB_OUTPUT
echo "BLUE_SITE_SFTP_PORT=$(echo $BLUE_SITE_SFTP_PORT)" >> $GITHUB_OUTPUT
echo "GREEN_SITE=$(echo $GREEN_SITE)" >> $GITHUB_OUTPUT
echo "GREEN_SITE_NAME=$(echo $GREEN_SITE_NAME)" >> $GITHUB_OUTPUT
echo "GREEN_SITE_ENV=$(echo $GREEN_SITE_ENV)" >> $GITHUB_OUTPUT
echo "GREEN_SITE_REPO=$(echo $GREEN_SITE_REPO)" >> $GITHUB_OUTPUT
echo "GREEN_SITE_SFTP_USER=$(echo $(echo $GREEN_SITE_SFTP_USER)" >> $GITHUB_OUTPUT
echo "GREEN_SITE_SFTP_HOST=$(echo $GREEN_SITE_SFTP_HOST)" >> $GITHUB_OUTPUT
echo "GREEN_SITE_SFTP_PORT=$(echo $GREEN_SITE_SFTP_PORT)" >> $GITHUB_OUTPUT