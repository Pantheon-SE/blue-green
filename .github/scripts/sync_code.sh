#!/bin/bash -e

# Required inputs
# - BLUE_SITE_ID
# - BLUE_SITE_REPO
# - GREEN_SITE_ID
# - GREEN_SITE_REPO
# - BASE_BRANCH

# Prepare git credentials
FNAME=$(terminus auth:whoami --field firstname)
LNAME=$(terminus auth:whoami --field lastname)
GIT_EMAIL=$(terminus auth:whoami --field email)
GIT_NAME="$FNAME $LNAME"

# Make sure env are in git mode
terminus connection:set $BLUE_SITE_ID.dev git
terminus connection:set $GREEN_SITE_ID.dev git

# Setup repo, add remote branch connection, sync code.
git clone $GREEN_REPO $GREEN_SITE_ID -b $BASE_BRANCH
cd $GREEN_SITE_ID
git remote add $BLUE_SITE_ID $BLUE_REPO

# Configure git defaults
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_NAME"
git config pull.rebase false

# Check if remote branch exists
_check_branch=$(git ls-remote --heads $BLUE_SITE_ID $BASE_BRANCH)
[[ -n ${_check_branch} ]] && git fetch $BLUE_SITE_ID && git merge $BLUE_SITE_ID/$BASE_BRANCH $BASE_BRANCH --no-edit --log

# Sync branch back to green
git push -u origin HEAD:refs/heads/$BASE_BRANCH
