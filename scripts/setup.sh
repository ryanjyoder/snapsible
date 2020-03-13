#!/usr/bin/env sh

if [ ! -z "$DEBUG" ]
then
    set -o xtrace
fi

if ! [ $(id -u) = 0 ]; then
   echo "Setup needs to be run as root."
   exit 1
fi

if [ -z "$CONFIG_DIR" ]
then
      echo "\$CONFIG_DIR must be set"
      exit 1
fi

mkdir -p "$CONFIG_DIR"
mkdir -p $HOME/.ssh


ssh_private_key="$DATA_DIR/.ssh/id_rsa"
if [ ! -f "$ssh_private_key" ]
then
    ssh-keygen -t rsa -f $ssh_private_key -q -N ""
fi

ssh_username_file="$CONFIG_DIR/ssh_username"
ssh_username=$SSH_USERNAME
if [ -z "$ssh_username" ]
then
    echo -n "Which user should be used to manage this device? (It must have ssh access): "
    read ssh_username
    echo -n "$ssh_username" > "$ssh_username_file"
fi

echo
echo "Connecting with username: $ssh_username."
echo "If this is incorrect delete this file an run the setup again: $ssh_username_file"
echo

ssh -i "$ssh_private_key" -q -o 'StrictHostKeyChecking=yes' -o BatchMode=yes -f $ssh_username@localhost exit
ssh_exit_status=$?

if [ "$ssh_exit_status" -ne "0" ]
then
    ssh_identity_option=""
    if [ -z "$EXISTING_SSH_KEY" ]
    then
        echo "No private key is set. Using password."
        echo "If you need to use a ssh key to connect to this device, do the following:"
        echo "\t1) Copy your ssh keys (id_rsa, id_rsa.pub) into $DATA_DIR."
        echo "\t1) Set the private key in the config: snap set snapsible existing-private-key=<$DATA_DIR/id_rsa "
        ssh_identity_option="$ssh_private_key"
    else
        echo "Using the ssh key provided: $EXISTING_SSH_KEY"
        ssh_identity_option="$EXISTING_SSH_KEY"
        chmod 600 $EXISTING_SSH_KEY
    fi
    #-o UserKnownHostsFile\ $ssh_known_hosts_file
    ssh-copy-id -i "$ssh_private_key" -f -oIdentityFile\ $ssh_identity_option "$ssh_username@localhost"
fi


ssh -i "$ssh_private_key" -f $ssh_username@localhost exit
ssh_exit_status=$?

if [ "$ssh_exit_status" -eq "0" ]
then
    echo "ssh setup success ✓"
    rm -f "$EXISTING_SSH_KEY" "$EXISTING_SSH_KEY.pub"
else
    echo "ssh connection setup failed."
    exit 1
fi

git_url_file="$CONFIG_DIR/git_url"
git_url="$GIT_URL"
if [ -z "$git_url" ]
then
    echo -n "git url to configure device: "
    read git_url
    echo -n "$git_url" > "$git_url_file"
fi

cd /tmp
git ls-remote -h  $git_url 2>/dev/null >/dev/null
git_exit_status=$?

echo
echo "Using git repo: $git_url."
echo "If this is incorrect delete this file an run the setup again: $git_url_file"
echo

if [ "$git_exit_status" -eq "0" ]
then
    echo "git setup success ✓"
else
    echo "Could not connect to the git repo"
    echo -n 'Considering adding this ssh key to the repo'\''s "deploy keys":\n\n\t'
    cat "$ssh_private_key.pub"
    exit 1
fi
