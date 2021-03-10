#!/bin/bash

export TERM=dumb # make tput shut up

# use our config
cp cloudbuild/configs."$CONFIG" configs/.configs.cloudbuild

echo "CONFIG DEBUG:"
./sultan config debug

echo "CLEANING UP:"
./sultan instance delete
