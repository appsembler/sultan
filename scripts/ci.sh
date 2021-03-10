#!/bin/bash

current_dir="$(dirname "$0")"
sultan_dir="$(dirname "$current_dir")"

# shellcheck source=scripts/messaging.sh
source "$current_dir/messaging.sh"

help_text="${NORMAL}An Open edX Remote Devstack Toolkit by Appsembler

${BOLD}${GREEN}ci${NORMAL}
  Helps you triggering and managing CI/CD commands from your local machine.

  ${BOLD}USAGE:${NORMAL}
    sultan ci <argument>

  ${BOLD}ARGUMENTS:${NORMAL}
    build         Triggering GCloud builds without pushing commits to the
                  remote repository.

  ${BOLD}EXAMPLES:${NORMAL}
    sultan ci build
"

build() {
  #############################################################################
  # Resumes suspended by creating an instance from the saved image, running   #
  # the devstack, and mounting it locally.                                    #
  #############################################################################
	message "Building..."

	SHORT_SHA=$(cd "$sultan_dir" || exit 1; git rev-parse --short HEAD)
	message "Fetched short SHA" "$SHORT_SHA"

	BRANCH_NAME=$(cd "$sultan_dir" || exit 1; git branch --show-current)
	message "Fetched branch name" "$BRANCH_NAME"

	gcloud builds submit \
	  --config=cloudbuild.yaml \
	  --config=cloudbuild.yaml \
	  --substitutions="REPO_NAME=sultan-$USER_NAME,BRANCH_NAME=$BRANCH_NAME,SHORT_SHA=$SHORT_SHA" \
	  --project="$PROJECT_ID"
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
