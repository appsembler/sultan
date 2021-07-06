#!/bin/bash

set -eo pipefail

echo "::group::Bring the devstack up"
./sultan devstack up
echo "::endgroup::"

# have to wait a while for devstack to start
echo "::group::Fetching the heartbeat"
n=0
HEARTBEAT=
until [ "$n" -ge 5 ]; do
  HEARTBEAT=$(curl -i -v http://devstack.tahoe:18010/heartbeat) && break
  n=$((n + 1))
  sleep 30
done
echo "::endgroup::"

echo "::group::Checking the heartbeat"
echo "$HEARTBEAT"
[[ "$HEARTBEAT" == *"HTTP/1.1 200 OK"* ]] || exit 2
echo "::endgroup::"
