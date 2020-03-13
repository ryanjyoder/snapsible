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


export SSH_USERNAME_FILE="$CONFIG_DIR/ssh_username"
export SSH_USERNAME=`[ -f $SSH_USERNAME_FILE ] && cat $SSH_USERNAME_FILE`

export DEBUG=`snapctl get debug`

exec "$@"