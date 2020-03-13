#!/usr/bin/env sh

###############
## CONSTANTS ##
###############
usage='(cd ~/.ssh/ && echo id_rsa.pub | cpio -oaV ) | ssh <username>@<host> sudo snapsible.setup'


######################
## Enable Debugging ##
######################
if [ ! -z "$DEBUG" ]
then
    set -o xtrace
fi




########################
## Check user is root ##
########################
if [ $(id -u) != 0 ]; then
    echo "This this script should be run as root."
    exit 1
fi




##########################
## Non-interactive mode ##
##########################
if [ -t 0 ]; then
    echo "Usage:"
    echo "\t$usage"
    exit 1
fi

#####################
## Import ssh keys ##
#####################
# This script expects the ssh keys to be piped to it.
temp_keys_dir=/tmp/temp_keys
rm -rf $temp_keys_dir
mkdir -p $temp_keys_dir
cur_umask=`umask` # save current umask to reset it later
umask 027
(cd $temp_keys_dir && cpio -imVd )
umask $cur_umask 
# Verify the keys were supplied. We're looking for files thatend in .pub. They should have only provided one, but there's more than one just take the first one.
temp_public_key_path=`ls -1 $temp_keys_dir/*.pub 2>/dev/null | head -n 1` 
if [ -z "$temp_public_key_path" ]
then
    echo
    echo "ERROR: No public keys were found in the provide tar."
    echo 
    echo "Usage:"
    echo "\t$usage"
    exit 1
fi
temp_private_key_path=`echo $temp_public_key_path|sed 's/.pub$//'`


####################################
## Validate Environment Variables ##
####################################
# Before starting we are going to override the ssh username
SSH_USERNAME=`logname`
required_envs="CONFIG_DIR:$CONFIG_DIR DATA_DIR:$DATA_DIR SSH_USERNAME:$SSH_USERNAME SSH_USERNAME_FILE:$SSH_USERNAME_FILE " 
for var in ${required_envs} ; do
    key=${var%%:*}
    value=${var#*:}
    if [ -z "$value" ]
    then
        echo "$key must be set"
        exit 1
    fi
done
mkdir -p $CONFIG_DIR
mkdir -p $DATA_DIR/.ssh



########################
## Create Private Key ##
########################
mkdir -p "$CONFIG_DIR"
mkdir -p $HOME/.ssh
ssh_private_key="$DATA_DIR/.ssh/id_rsa"
if [ ! -f "$ssh_private_key" ]
then
    ssh-keygen -t rsa -f $ssh_private_key -q -N ""
fi


########################
## Update Known_hosts ##
########################
new_known_hosts_file=/tmp/known_hosts
current_known_hosts_file=$DATA_DIR/.ssh/known_hosts
if [ ! -f "$current_known_hosts_file" ]
then
    touch $current_known_hosts_file
    chmod 600 $current_known_hosts_file
fi
cp $current_known_hosts_file $new_known_hosts_file
ssh-keyscan -H localhost 2>/dev/null >> $new_known_hosts_file
current_hash=`sort $current_known_hosts_file | uniq | md5sum`
new_hash=`sort $new_known_hosts_file | uniq | md5sum`
if [ "$new_hash" = "$current_hash" ]
then
    # Nothing changed. Just delete the file
    rm $new_known_hosts_file
else
    # Something has changed. Replace the old file
    mv $new_known_hosts_file $current_known_hosts_file
fi






##############################
## Save SSH username config ##
##############################
echo -n "$SSH_USERNAME" > "$SSH_USERNAME_FILE"




########################
## Set SSH Connection ##
########################
# We want to make sure that ansible can connect with our private key without being prompted. If we cannot connect with ssh, then we neet to do the setup.
ssh -i "$ssh_private_key" -q -o BatchMode=yes -f $SSH_USERNAME@localhost exit
ssh_exit_status=$?
if [ "$ssh_exit_status" -ne "0" ]
then
    # The ssh connection failed. Let's set up the connection.
    ssh-copy-id -i "$ssh_private_key" -f -oIdentityFile\ $temp_private_key_path "$SSH_USERNAME@localhost"
fi
# We are not finished with these keys. Delete them so they aren't laying around.
rm -rf $temp_keys_dir



##########################
## Confirm Setup worked ## 
##########################
ssh -i "$ssh_private_key" -f $SSH_USERNAME@localhost exit
ssh_exit_status=$?
if [ "$ssh_exit_status" -eq "0" ]
then
    echo "ssh setup success ✓"
else
    echo "ssh connection setup failed."
    exit 1
fi
