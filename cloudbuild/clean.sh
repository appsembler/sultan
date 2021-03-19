#!/bin/bash

set -eo pipefail

export TERM=dumb # make tput shut up
export TERM=xterm-256color # make tput shut up

echo "Build script exited with status $PREVIOUS_EXIT"

echo "CLEANING UP:"
./sultan instance delete

exit "$PREVIOUS_EXIT"
