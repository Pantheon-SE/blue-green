#!/bin/bash -e

# Required inputs
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

# Fix github actions variables missing periods.
BLUE_REPO=$(echo "ssh://codeserver.dev.$BLUE_SITE_NAME@codeserver.dev.$BLUE_SITE_NAME.drush.in:2222/~/repository.git")
GREEN_REPO=$(echo "ssh://codeserver.dev.$GREEN_SITE_NAME@codeserver.dev.$GREEN_SITE_NAME.drush.in:2222/~/repository.git")

# Make sure env are in git mode
terminus connection:set $BLUE_SITE_NAME git
terminus connection:set $GREEN_SITE_NAME git

# Setup repo, add remote branch connection, sync code.
git clone $GREEN_REPO $GREEN_SITE_NAME -b $BASE_BRANCH
cd $GREEN_SITE_NAME
git remote add $BLUE_SITE_NAME $BLUE_REPO

# Check if remote branch exists
_check_branch=$(git ls-remote --heads $BLUE_SITE_NAME $BASE_BRANCH)
[[ -n ${_check_branch} ]] && git pull $BLUE_SITE_NAME $BASE_BRANCH --rebase
# Sync branch
git pull origin $BASE_BRANCH -x theirs
git push -u origin HEAD:refs/heads/$BASE_BRANCH
