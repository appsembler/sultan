#!/bin/bash

set -eo pipefail

echo "::group::Start the SSH agent"
eval "$(ssh-agent -s)"
echo "::endgroup::"

if [[ "$IMAGE" ]]; then
  echo "::group::Setting up the instance from $IMAGE"
  ./sultan instance setup --image "$IMAGE"
  echo "::endgroup::"

  echo "::group::Scanning github.com"
  ./sultan instance run "ssh-keyscan github.com >> ~/.ssh/known_hosts"
  echo "::endgroup::"

  echo "::group::Installing requirements"
  ./sultan devstack make requirements
  echo "::endgroup::"

  echo "::group::Clone devstack repos"
  ./sultan devstack make dev.clone
  echo "::endgroup::"

  echo "::group::Pulling devstack images"
  ./sultan devstack make dev.pull
  echo "::endgroup::"
else
  echo "::group::Setting up the instance"
  ./sultan instance setup
  echo "::endgroup::"
fi

echo "::group::Make sure the instance is pingable"
./sultan instance ping
echo "::endgroup::"
