#!/usr/bin/env sh

###############
## CONSTANTS ##
###############
usage='sudo snapsible.setup'


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
    echo "This this script should be run as root:"
    echo "\t$usage"
    exit 1
fi





####################################
## Validate Environment Variables ##
####################################
# Before starting we are going to override the ssh username
SSH_USERNAME=`logname`
required_envs="CONFIG_DIR:$CONFIG_DIR DATA_DIR:$DATA_DIR SSH_USERNAME:$SSH_USERNAME SSH_USERNAME_FILE:$SSH_USERNAME_FILE SECRET_CODE_FILE:$SECRET_CODE_FILE" 
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
ssh_keys_dir=$DATA_DIR/.ssh


########################
## Create Private Key ##
########################
mkdir -p $ssh_keys_dir
ssh_private_key="$ssh_keys_dir/id_rsa"
ssh_public_key="$ssh_keys_dir/id_rsa.pub"
if [ ! -f "$ssh_private_key" ]
then
    ssh-keygen -t rsa -f $ssh_private_key -q -N ""
fi


########################
## Update Known_hosts ##
########################
new_known_hosts_file=/tmp/known_hosts
current_known_hosts_file=$ssh_keys_dir/known_hosts
if [ ! -f "$current_known_hosts_file" ]
then
    touch $current_known_hosts_file
    chmod 600 $current_known_hosts_file
fi
cp $current_known_hosts_file $new_known_hosts_file
ssh-keyscan -H localhost 2>/dev/null >> $new_known_hosts_file
ssh-keyscan -H 127.0.0.1 2>/dev/null >> $new_known_hosts_file
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



##########################
## Confirm Setup worked ## 
##########################
ssh -i "$ssh_private_key" -q -o BatchMode=yes -f $SSH_USERNAME@localhost exit
ssh_exit_status=$?
if [ "$ssh_exit_status" -eq "0" ]
then
    echo "ssh setup success ✓"
else
    echo "To complete the setup you will need to run the following:"
    echo "\tsudo cat $ssh_public_key >> ~/.ssh/authorized_keys"
    echo
    echo "When you've run the above command. Run the setup again to get your secret code"
    exit 1
fi




######################################
## Create Device ID and Secret Code ##
######################################

if [ -z "$DEVICE_ID" ]
then
    DEVICE_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    echo "$device_id" > $DEVICE_ID_FILE
fi

if [ -z "$SECRET_CODE" ]
then
    SECRET_CODE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    temp_secret_file="$SECRET_CODE_FILE.tmp"
    touch $temp_secret_file
    chmod 600 $temp_secret_file
    if [ "$?" != "0" ]
    then
        echo "Couldn't chmod secret file"
        exit 1
    fi
    echo "$secret" > $temp_secret_file
    mv $temp_secret_file $SECRET_CODE_FILE

fi

secret_json=`printf '{"device-id":"%s", "secret":"%s", "mqtt-broker":"%s"}' $device_id $secret $MQTT_BROKER`
echo -e "Your device secret code is:\n\t"
echo $secret_json | base64 -w 0
echo
echo

snapctl start snapsible