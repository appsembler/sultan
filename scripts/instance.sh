#!/bin/sh

current_dir="$(dirname "$0")"
source "$current_dir/messaging.sh"

# Source configurations variables
source configs/.configs
for f in configs/.configs.*; do source $f; done


ping() {
  #############################################################################
  #  Performs a ping to your instance.                                        #
  #############################################################################
	. $ACTIVATE; ansible -i $INVENTORY $INSTANCE_NAME -m ping \
	    || error "Unable to ping instance!"
}

restrict() {
  #############################################################################
  #  Restricts the access to your instance to you only by creating the        #
  #  necessary rules.                                                         #
  #############################################################################
  ./sultan firewall deny refresh
  ./sultan firewall allow refresh

  if [ $RESTRICT_INSTANCE == true ]; then
    public_ip=$(curl -s ifconfig.me)
    success "The instance only communicates with your IP now" $public_ip
  else
    warn "The instance accepts requests from any IP now." "0.0.0.0/0"
  fi

  dim "If this is not the expected behavior, consider toggling the instance restriction setting RESTRICT_INSTANCE in your env file."
}

delete() {
  #############################################################################
  # Deletes your instance from GCP.                                           #
  #############################################################################
  message "Deleting your virtual machine from GCP..." $INSTANCE_NAME

  ./sultan local hosts revert
	./sultan firewall clean

	(gcloud compute instances delete $INSTANCE_NAME \
		--quiet \
		--zone=$ZONE \
		--verbosity $VERBOSITY \
		--project $PROJECT_ID && success "Your virtual machine has been deleted successfully!") \
	|| message 'No previous instance found'
}

create() {
  #############################################################################
  # Creates an empty instance for you on GCP.                                 #
  #############################################################################
  message "Creating your virtual machine on GCP..." $INSTANCE_NAME
	gcloud compute instances create $INSTANCE_NAME \
		--image-family=ubuntu-1804-lts \
		--image-project=gce-uefi-images \
		--boot-disk-size=$DISK_SIZE \
		--machine-type=$MACHINE_TYPE \
		--tags=devstack,http-server,$INSTANCE_TAG \
		--zone=$ZONE \
		--verbosity=$VERBOSITY \
		--project=$PROJECT_ID
	success "Your virtual machine has been successfully created!"
}

deploy() {
  #############################################################################
  # Deploys the instance to install required libraries and software.          #
  #############################################################################
	message "Deploying your instance..." $INSTANCE_NAME
	. $ACTIVATE; ansible-playbook devstack.yml \
		-i $INVENTORY \
		-e "instance_name=$INSTANCE_NAME working_directory=$DEVSTACK_WORKSPACE git_repo_url=$DEVSTACK_REPO_URL openedx_release=$OPENEDX_RELEASE git_repo_branch=$DEVSTACK_REPO_BRANCH virtual_env_dir=$VIRTUAL_ENV" &> $SHELL_OUTPUT
	success "Your virtual machine has been deployed successfully!"
	message "Run devstack provision to start provisioning your devstack."
}

provision() {
  #############################################################################
  # Provisions the devstack on your instance.                                 #
  #############################################################################
	./sultan devstack make requirements
	./sultan devstack make dev.clone
	./sultan devstack make dev.pull
	./sultan devstack make dev.provision

	success "The devstack has been provisioned successfully!"
	message "Run make devstack run to start devstack servers."
}

start() {
  #############################################################################
  # Starts your stopped instance on GCP.                                      #
  #############################################################################
	message "Starting your virtual machine on GCP..." $INSTANCE_NAME
	gcloud compute instances start $INSTANCE_NAME \
		--zone=$ZONE \
		--project $PROJECT_ID

	./sultan local hosts update
	./sultan local ssh config
	success "Your virtual machine has been started successfully!"
}

stop() {
  #############################################################################
  # Stops your instance on GCP, but doesn't delete it.                        #
  #############################################################################
  ./sultan local hosts revert

	message "Stopping your virtual machine on GCP..." $INSTANCE_NAME
	gcloud compute instances stop $INSTANCE_NAME \
		--zone=$ZONE \
		--project $PROJECT_ID
	success "Your virtual machine has been stopped successfully!"
}

full_setup() {
  ./sultan local clean
  delete
  create
  restrict
	./sultan local hosts update
	./sultan local ssh config
  deploy
  provision

  success "Your instance has been successfully created!"
}

image_setup() {
  image_name="${1:-$IMAGE_NAME}"

	message "Setting up a new instance from your image..."

  # Clean local env and delete the current GCP instance if any
  ./sultan local clean
  delete

  # Setting up the image
	gcloud compute instances create $INSTANCE_NAME \
		--image=$image_name \
		--image-project=$PROJECT_ID \
		--boot-disk-size=$DISK_SIZE \
		--machine-type=$MACHINE_TYPE \
		--tags=devstack,http-server,$INSTANCE_TAG \
		--zone=$ZONE \
		--project=$PROJECT_ID

  # Restrict VM to work with this machine only
  restrict

	./sultan local hosts update
	./sultan local ssh config

	message "Personalizing your instance..."
	$ACTIVATE; ansible-playbook devstack.yml \
		-i $INVENTORY \
		--tags "reconfiguration,never"  \
		-e "instance_name=$INSTANCE_NAME user=$USER_NAME working_directory=$DEVSTACK_WORKSPACE" &> $SHELL_OUTPUT

	success "Your instance has been successfully created!" "From $IMAGE_NAME"
	message "Run make instance.start and then make devstack run to start devstack servers."
}

describe() {
  #############################################################################
  # Describes your virtual machine instance                                   #
  #############################################################################
  gcloud compute instances describe $INSTANCE_NAME \
    --quiet \
    --zone=$ZONE \
    --verbosity $VERBOSITY \
    --project $PROJECT_ID \
  || warn "No instance found" "SKIPPING"
}

status() {
  #############################################################################
  # Shows the status of your running machine.                                 #
  #############################################################################
  gcloud compute instances describe $INSTANCE_NAME \
    --quiet \
    --zone=$ZONE \
    --verbosity $VERBOSITY \
    --format='value[](status)' \
    --project $PROJECT_ID \
  || warn "No instance found" "SKIPPING"
}

setup() {
  full_setup=1
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -i|--image) image=$2; full_setup=0 shift;;
      *) error "Unknown parameter passed: $1" ;;
    esac
    shift
  done

  if [ $full_setup -eq 1 ]; then
    full_setup
  else
    image_setup $image
  fi
}

ip() {
  #############################################################################
  # Gets the external IP of your instance.                                    #
  #############################################################################
  gcloud compute instances describe $INSTANCE_NAME \
		--zone=$ZONE \
		--project=$PROJECT_ID \
		--format='get(networkInterfaces[0].accessConfigs[0].natIP)'
}

run() {
  #############################################################################
  # SSH into or run commands on your instance.                                  #
  #############################################################################
  ssh -tt devstack "$@"
}

"$@"
