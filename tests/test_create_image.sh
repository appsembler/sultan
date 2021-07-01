#!/bin/bash

set -eo pipefail

echo "::group::Start the SSH agent"
eval "$(ssh-agent -s)"
echo "::endgroup::"


echo "::group::Setup the instance"
./sultan instance setup --image "$IMAGE"
echo "::endgroup::"


echo "::group::Create the image"
./sultan image create --name "${IMAGE}"
echo "::endgroup::"
