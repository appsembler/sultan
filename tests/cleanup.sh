#!/bin/bash

set -eo pipefail

echo "::group::Deleting the instance"
./sultan instance delete
echo "::endgroup::"

echo "::group::remove files"
rm -rf "$SERVICE_KEY_LOCATION"
rm -rf "$SSH_KEY_LOCATION"
echo "::endgroup::"
