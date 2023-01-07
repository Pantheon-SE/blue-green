#!/bin/bash -e

# Required inputs
# - BLUE_SITE_REPO
# - GREEN_SITE_REPO
# - BLUE_SITE_NAME
# - GREEN_SITE_NAME
# - BASE_BRANCH

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
git clone $GREEN_SITE_REPO $GREEN_SITE_NAME && cd $GREEN_SITE_NAME
git remote add $BLUE_SITE_NAME $BLUE_SITE_REPO

# Check if remote branch exists
_check_branch=$(git ls-remote --heads $BLUE_SITE_NAME $BASE_BRANCH)
[[ -n ${_check_branch} ]] && git pull $BLUE_SITE_NAME $BASE_BRANCH --rebase
# Sync branch
git push -u $GREEN_SITE_NAME HEAD:refs/heads/$BASE_BRANCH
