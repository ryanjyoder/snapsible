#!/usr/bin/env sh

##
## 
## This script is used as a command-chain in the snap. It will set the following environment variables:
##      DATA_DIR    : A generic renaming of SNAP_DIR
##      CONFIG_DIR  : A directory hold configuration files: eg, ssh_username, git_url
##      GIT_URL     : The git repo that will be used to configure the device.
##      SSH_USERNAME: The username for configuring the device.


export DATA_DIR=$SNAP_DATA
export CONFIG_DIR=$SNAP_DATA/config
export HOME=$SNAP_DATA

export EXISTING_SSH_KEY=`snapctl get existing-private-key`

git_url_file=$CONFIG_DIR/git_url
export GIT_URL=`[ -f $git_url_file ] && cat $git_url_file`


ssh_username_file="$CONFIG_DIR/ssh_username"
export SSH_USERNAME=`[ -f $ssh_username_file ] && cat $ssh_username_file`

export DEBUG=`snapctl get debug`

exec "$@"