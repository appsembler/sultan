#!/bin/bash

set -eo pipefail

env

# get our service key file out of secret manager
echo "PROJECT_ID: $GCP_PROJECT_ID"
gcloud secrets versions access latest --secret=devstack-service-key --project="$GCP_PROJECT_ID" > /tmp/devstack.json

ls -la /tmp/
## get our SSH key
#mkdir /root/.ssh
#chmod 700 /root/.ssh
#gcloud secrets versions access latest --secret=cloudbuild-ssh-key --project="$PROJECT_ID" > /root/.ssh/id_ed25519
#chmod 600 /root/.ssh/id_ed25519
#
## sultan expects sudo to be installed
#apt-get update
#apt-get install -y sudo
#
#export USER=cloudbuild
#export HOME=/root
#export TERM=xterm-256color # make tput shut up
#
#eval "$(ssh-agent -s)" # Start the SSH agent
#
## cloudbuild environment requires some trickiness
#mkdir /tmp/.ansible
#export ANSIBLE_SSH_ARGS="-C -o ControlMaster=auto -o ControlPersist=60s -o 'ControlPath=/tmp/.ansible/ansible-ssh-%h-%p-%r'"
#
## set up requirements
#pip install -r requirements.txt
#
## use our config
#cp cloudbuild/configs."$CONFIG" configs/.configs.cloudbuild
#
#echo "CONFIG DEBUG:"
#./sultan config debug
#
#echo "INSTANCE SETUP:"
#if [[ "$IMAGE" ]]; then
#  ./sultan instance setup --image "$IMAGE"
#else
#  ./sultan instance setup
#fi
#
#echo "ROOT SSH CONFIG:"
#cat /root/.ssh/config
#
#echo "/ETC/HOSTS:"
#cat /etc/hosts
#
#echo "INSTANCE IP:"
#./sultan instance ip
#
#echo "INSTANCE STATUS:"
#./sultan instance status
#
#echo "BRINGING UP THE DEVSTACK:"
#./sultan devstack up
#
#echo "TEST IT:"
#echo "Make sure the instance is pingable:"
#./sultan instance ping
#
## have to wait a while for it to start
#n=0
#HEARTBEAT=
#until [ "$n" -ge 5 ]; do
#  HEARTBEAT=$(curl -i -v http://devstack.tahoe:18010/heartbeat) && break
#  n=$((n + 1))
#  sleep 30
#done
#
#echo "Checking the heartbeat:"
#echo "$HEARTBEAT"
#[[ "$HEARTBEAT" == *"HTTP/1.1 200 OK"* ]] || exit 2
#
#echo "Checking instance alive time:"
#n=0
#ALIVE_TIME=240
#./sultan instance setup --image "${IMAGE}" --alive-time "$ALIVE_TIME"
#
#until [ "$n" -ge 3 ]; do
#  echo "Reading instance status"
#  INSTANCE_STATUS=$(./sultan instance status)
#  n=$((n + 1))
#  if [ "$INSTANCE_STATUS" != "TERMINATED" ]; then
#    sleep $ALIVE_TIME
#  fi
#done
#[[ "$INSTANCE_STATUS" == "TERMINATED" ]] || (echo "Instance failed to terminate itself. Status: $INSTANCE_STATUS" exit 3)
#echo "Instance terminated itself successfully."
#
#if [ "$GITHUB_REF" == "refs/heads/master" ] && { [ "$DEVSTACK_BRANCH" == "juniper" ] || [ -z "$DEVSTACK_BRANCH" ]; }; then
#  # The condition needs to be changed when more repos are involved.
#  echo "Create image:"
#  ./sultan image create --name "${IMAGE}"
#fi
