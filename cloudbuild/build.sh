#!/bin/bash

set -eo pipefail

env

# get our service key file out of secret manager
gcloud secrets versions access latest --secret=devstack-service-key --project="$PROJECT_ID" > /workspace/devstack.json

# get our SSH key
mkdir /root/.ssh
chmod 700 /root/.ssh
gcloud secrets versions access latest --secret=cloudbuild-ssh-key --project="$PROJECT_ID" > /root/.ssh/id_ed25519
chmod 600 /root/.ssh/id_ed25519

# sultan expects sudo to be installed
apt-get update
apt-get install -y sudo

# TODO: distinct firewall, image, and instance names
export USER=cloudbuild
export HOME=/root
export TERM=dumb  # make tput shut up

# cloudbuild environment requires some trickiness
mkdir /tmp/.ansible
export ANSIBLE_SSH_ARGS="-C -o ControlMaster=auto -o ControlPersist=60s -o 'ControlPath=/tmp/.ansible/ansible-ssh-%h-%p-%r'"

# set up requirements
pip install -r requirements.txt

# use our config
cp cloudbuild/configs."$CONFIG" configs/.configs.cloudbuild

echo "CONFIG DEBUG:"
./sultan config debug

echo "INSTANCE SETUP:"
if [[ "$IMAGE" ]]; then
  ./sultan instance setup --image "$IMAGE"
else
  ./sultan instance setup
fi

echo "ROOT SSH CONFIG:"
cat /root/.ssh/config

echo "/ETC/HOSTS:"
cat /etc/hosts

echo "INSTANCE IP:"
./sultan instance ip

echo "INSTANCE STATUS:"
./sultan instance status

echo "BRINGING UP THE DEVSTACK:"
./sultan devstack up

echo "TEST IT:"
echo "Make sure the instance is pingable"
./sultan instance ping

echo "Checking the heartbeat"
# have to wait a while for it to start
n=0
HEARTBEAT=
until [ "$n" -ge 5 ]; do
  HEARTBEAT=$(curl -i -v http://edx.devstack.lms:18010/heartbeat) && break
  n=$((n + 1))
  sleep 30
done

[[ "$HEARTBEAT" = *"HTTP/1.1 200 OK"* ]] && echo "Heartbeat status OK :)"

echo "Create image:"
./sultan image create

echo "CLEANING UP:"
./sultan instance stop
./sultan instance delete
