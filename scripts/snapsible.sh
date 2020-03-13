#!/usr/bin/env sh

if ! [ -z "$DEBUG" ]
then
    set -o xtrace
fi


if ! [ $(id -u) = 0 ]; then
   echo "Setup needs to be run as root."
   exit 1
fi


if [ -z "$DATA_DIR" ]
then
    echo "DATA_DIR must be set. Run setup."
    exit 1
fi

if [ -z "$DATA_DIR" ]
then
    echo "GIT_URL must be set. Run setup."
    exit 1
fi


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