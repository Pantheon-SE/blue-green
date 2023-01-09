#!/bin/bash
sudo ln -s $GITHUB_WORKSPACE/.github/exe/terminus.phar /usr/local/bin/terminus
terminus auth:login --machine-token=$PANTHEON_MACHINE_TOKEN