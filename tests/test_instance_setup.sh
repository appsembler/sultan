#!/bin/bash

set -eo pipefail

echo "::group::Start the SSH agent"
eval "$(ssh-agent -s)"
echo "::endgroup::"

echo "::group::Setting up the instance"
if [[ "$IMAGE" ]]; then
  ./sultan instance setup --image "$IMAGE"
else
  ./sultan instance setup
fi
echo "::endgroup::"

echo "::group::Make sure the instance is pingable"
./sultan instance ping
echo "::endgroup::"
