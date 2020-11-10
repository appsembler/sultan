#!/bin/bash

current_dir="$(dirname "$0")"
# shellcheck source=scripts/messaging.sh
source "$current_dir/messaging.sh"

help_text="${NORMAL}An Open edX Remote Devstack Toolkit by Appsembler

${BOLD}${GREEN}workflow${NORMAL}
  Helps you suspending and resuming working on your instance.

  ${BOLD}USAGE:${NORMAL}
    sultan workflow <argument>

  ${BOLD}ARGUMENTS:${NORMAL}
    suspend       Suspends work by stopping the devstack, remove the mount,
                  and create an GCP image for future use.
    resume        Resumes suspended by creating an instance from the saved
                  image, running the devstack, and mounting it locally.

  ${BOLD}EXAMPLES:${NORMAL}
    sultan workflow suspend
    sultan workflow resume
"

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

help() {
  # shellcheck disable=SC2059
  printf "$help_text"
}

# Print help message if command is not found
if ! type -t "$1" | grep -i function > /dev/null; then
  help
  exit 1
fi

"$@"
