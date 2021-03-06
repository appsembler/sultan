#!/bin/bash

set -eo pipefail

echo "::group::Start the SSH agent"
eval "$(ssh-agent -s)"
echo "::endgroup::"


echo "::group::Setup the instance"
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


echo "::group::Create the image"
./sultan image create --name "${IMAGE}"
echo "::endgroup::"
