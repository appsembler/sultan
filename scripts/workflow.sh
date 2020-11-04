#!/bin/bash

current_dir="$(dirname "$0")"
# shellcheck source=scripts/messaging.sh
source "$current_dir/messaging.sh"

suspend() {
  #############################################################################
  # Suspends work by stopping the devstack, remove the mount, and create an   #
  # GCP image for future use                                                  #
  #############################################################################
	echo "Making a new image and stopping the instance..."

  ./sultan devstack stop
  ./sultan instance stop
  ./sultan image create
}

resume() {
  #############################################################################
  # Resumes suspended by creating an instance from the saved image, running   #
  # the devstack, and mounting it locally.                                    #
  #############################################################################
	message "Recreating instance from the image and starting it up..."

  ./sultan instance setup --image "$IMAGE_NAME"
  ./sultan devstack up
  ./sultan devstack mount
}

"$@"
