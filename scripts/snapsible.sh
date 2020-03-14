#!/usr/bin/env sh

if ! [ -z "$DEBUG" ]
then
    set -o xtrace
fi


if ! [ $(id -u) = 0 ]; then
   echo "Setup needs to be run as root."
   exit 1
fi



####################################
## Validate Environment Variables ##
####################################
# Before starting we are going to override the ssh username
SSH_USERNAME=`logname`
required_envs="CONFIG_DIR:$CONFIG_DIR DATA_DIR:$DATA_DIR SSH_USERNAME:$SSH_USERNAME  SECRET_CODE:$SECRET_CODE DEVICE_ID:$DEVICE_ID MQTT_BROKER:$MQTT_BROKER" 
for var in ${required_envs} ; do
    key=${var%%:*}
    value=${var#*:}
    if [ -z "$value" ]
    then
        echo "$key must be set"
        exit 1
    fi
done


mosquitto.sub -t $DEVICE_ID -h $MQTT_BROKER

## testing
exit 0

repo_path=$DATA_DIR/repo/`echo $GIT_URL | 
    sed 's/^.*:\/\///' | # strip protocol
    sed 's/^git@//' | #
    sed 's/\.git$//'` # strip .git at end


mkdir -p $repo_path

if [ ! -f "$repo_path/.git" ]
then
    git clone $GIT_URL $repo_path
fi

cd $repo_path

git pull

playbook="local.yml"
if [ ! -z "$PROFILE" ]
then
    playbook="$PROFILE.yml"
fi

inventory_file=$DATA_DIR/hosts
if [ -f hosts ]
then
    inventory_file=./hosts
fi


snapcraft-preload  $SNAP/usr/bin/python3 $SNAP/bin/ansible-playbook --user "$SSH_USERNAME" -i $inventory_file $playbook