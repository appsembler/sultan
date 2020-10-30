#!/bin/sh

current_dir="$(dirname "$0")"
source "$current_dir/messaging.sh"

# Source configurations variables
source configs/.configs
for f in configs/.configs.*; do source $f; done

delete_command() {
	(gcloud compute images delete $1 \
		--project=$PROJECT_ID \
		--verbosity $VERBOSITY \
		--quiet && \
	success "Image deleted successfully!") || dim "Couldn't find the image on GCP." "SKIPPING"
}

create_command() {
  (gcloud beta compute images create $1 \
		--source-disk=$INSTANCE_NAME \
		--source-disk-zone=$ZONE \
		--family=$IMAGE_FAMILY \
		--labels=user=$INSTANCE_NAME \
		--project=$PROJECT_ID \
		--verbosity $VERBOSITY \
		--quiet && \
	success "Your image has been created successfully!") || warn "Couldn't create an image on GCP." $1
}


delete() {
  #############################################################################
  # Deletes your image from GCP.                               #
  #############################################################################
  image_name=$IMAGE_NAME

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -n|--name) image_name=$2; shift;;
      *) throw_error "Unknown parameter passed: $1" ;;
    esac
    shift
  done

  message "Removing image from GCP..." $image_name
	delete_command $image_name
}

create() {
  #############################################################################
  # Creates an image from your devstack instance on GCP.                               #
  #############################################################################
  image_name=$IMAGE_NAME

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -n|--name) image_name=$2; shift;;
      *) error "Unknown parameter passed: $1" ;;
    esac
    shift
  done

  # Stop the instance
  ./sultan instance stop

	message "Creating a new image from your devstack GCP instance..." $image_name
	dim "This will remove any previous image with the same name. Press CTRL+C to abort..."

	# Give a short time for user to hit CTRL+C before execution starts
	sleep 10

	delete_command $image_name
	message "Image is being created..." $image_name
	create_command $image_name
}

"$@"
