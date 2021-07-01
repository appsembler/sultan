#!/bin/bash

set -eo pipefail

echo "::group::Create a new instance"
ALIVE_TIME=60
./sultan instance delete
./sultan instance create --alive-time "$ALIVE_TIME" --image "$IMAGE"
echo "::endgroup::"


echo "::group::Read instance status"
n=0
until [ "$n" -ge 5 ]; do
  echo "Reading instance status"
  INSTANCE_STATUS=$(./sultan instance status)
  n=$((n + 1))

  if [ "$INSTANCE_STATUS" != "TERMINATED" ] && [ "$INSTANCE_STATUS" != "STOPPING" ]; then
    sleep "$ALIVE_TIME"
  fi
done
echo "::endgroup::"

echo "::group::Check instance status"
[[ "$INSTANCE_STATUS" == "TERMINATED" || "$INSTANCE_STATUS" == "STOPPING" ]] || (echo "Instance failed to terminate itself. Status: $INSTANCE_STATUS"; exit 3)
echo "Instance terminated itself successfully."
echo "::endgroup::"
