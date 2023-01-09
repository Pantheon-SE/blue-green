#!/bin/bash
sudo ln -s $GITHUB_WORKSPACE/.github/exe/terminus.phar /usr/local/bin/terminus
#debug
echo "terminus auth:login --machine-token=$PANTHEON_MACHINE_TOKEN"
terminus auth:login --machine-token=$PANTHEON_MACHINE_TOKEN