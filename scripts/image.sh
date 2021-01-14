#!/bin/bash

current_dir="$(dirname "$0")"
sultan="$(dirname "$current_dir")"/sultan

# shellcheck source=scripts/messaging.sh
source "$current_dir/messaging.sh"


help_text="${NORMAL}An Open edX Remote Devstack Toolkit by Appsembler

${BOLD}${GREEN}image${NORMAL}
  Manages GCP images creation and deletion on GCP. All images you create are
  being created from your machine.

  ${BOLD}USAGE:${NORMAL}
    sultan image <command> [OPTION]

  ${BOLD}COMMANDS:${NORMAL}
    create      Creates an image from your devstack instance on GCP.
    delete      Deletes your image from GCP.

  ${BOLD}OPTIONS:${NORMAL}
    -n, --name  The name of the image you want to create. It defaults to
                the value of IMAGE_NAME in configurations file.
"


_delete_command() {
	(gcloud compute images delete "$1" \
		--project="$PROJECT_ID" \
		--verbosity "$VERBOSITY" \
		--quiet && \
	success "Image deleted successfully!") || dim "Couldn't find the image on GCP." "SKIPPING"
}

_create_command() {
  (gcloud beta compute images create "$1" \
		--source-disk="$INSTANCE_NAME" \
		--source-disk-zone="$ZONE" \
		--family="$IMAGE_FAMILY" \
		--labels=user="$INSTANCE_NAME" \
		--project="$PROJECT_ID" \
		--verbosity "$VERBOSITY" \
		--quiet && \
	success "Your image has been created successfully!") || warn "Couldn't create an image on GCP." "$1"
}


delete() {
  #############################################################################
  # Deletes your image from GCP.                                              #
  #############################################################################
  img_name="$IMAGE_NAME"

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -n|--name) img_name="$2"; shift;;
      *) error "Unknown parameter passed: $1" "$help_text";;
    esac
    shift
  done

  message "Removing image from GCP..." "$img_name"
	_delete_command "$img_name"
}

create() {
  #############################################################################
  # Creates an image from your devstack instance on GCP.                               #
  #############################################################################
  img_name=$IMAGE_NAME

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -n|--name) img_name="$2"; shift;;
      *) error "Unknown parameter passed: $1" "$help_text";;
    esac
    shift
  done

  # Stop the instance
  $sultan instance stop

	message "Creating a new image from your devstack GCP instance..." "$img_name"
	dim "This will remove any previous image with the same name. Press CTRL+C to abort..."

	# Give a short time for user to hit CTRL+C before execution starts
	sleep 10

	_delete_command "$img_name"
	message "Image is being created..." "$img_name"
	_create_command "$img_name"
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
