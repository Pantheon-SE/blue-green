#!/bin/bash
sudo ln -s $GITHUB_WORKSPACE/.github/exe/terminus.phar /usr/local/bin/terminus
terminus auth:login --machine-token="$pantheon-machine-token"