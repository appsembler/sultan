#!/bin/bash

current_dir="$(dirname "$0")"
sultan_dir="$(dirname "$current_dir")"
sultan="$sultan_dir"/sultan

# shellcheck source=scripts/messaging.sh
source "$current_dir/messaging.sh"


help_text="${NORMAL}An Open edX Remote Devstack Toolkit by Appsembler

${BOLD}${GREEN}instance${NORMAL}
  Manages all of your GCP instance aspects.

  ${BOLD}USAGE:${NORMAL}
    sultan instance (<command> | setup [OPTIONS] | create [OPTIONS])

  ${BOLD}COMMANDS:${NORMAL}
    ping              Performs a ping to your instance.
    restrict          Restricts the access to your instance to you only by
                      creating the necessary rules.
    delete            Deletes your instance from GCP.
    create            Creates an empty instance for you on GCP.
    deploy            Deploys the instance to install required libraries and
                      software.
    provision         Provisions the devstack on your instance.
    start             Starts your stopped virtual machine on GCP.
    stop              Stops your virtual machine on GCP, but doesn't delete it.
    restart           Restarts your virtual machine on GCP.
    describe          Describes your virtual machine instance.
    status            Shows the status of your running machine.
    setup             Setup a restricted instance for you on GCP contains a
                      provisioned devstack.
    ip                Gets the external IP of your instance.
    run               SSH into or run commands on your instance.

  ${BOLD}OPTIONS:${NORMAL}
    -i, --image       If supplied, the instance will be created from the image
                      name you provide, or the IMAGE_NAME configuration value.
    -a, --alive-time  Override the value of ALIVE_TIME configuration.

  ${BOLD}EXAMPLES:${NORMAL}
    sultan instance status
    sultan instance ip
    sultan instance setup
    sultan instance setup --image
    sultan instance setup --image devstack-juniper --alive-time 240
"


ping() {
  #############################################################################
  #  Performs a ping to your instance.                                        #
  #############################################################################
    # shellcheck disable=SC1090
    ansible -i "$INVENTORY" "$INSTANCE_NAME" -u "$USER_NAME" -m ping \
	|| error "Unable to ping instance!" "This might be caused by one of the following reasons:
    * The instance is not set up yet. To set up an instance run ${BOLD}${CYAN}sultan instance setup${NORMAL}${MAGENTA}
    * The instance was stopped. Check the status of your instance using ${BOLD}${CYAN}sultan instance status${NORMAL}${MAGENTA} and start it by running ${BOLD}${CYAN}sultan instance start${NORMAL}${MAGENTA}
    * The instance might have been restricted under a previous IP of yours. To allow your current IP from accessing the instance run ${BOLD}${CYAN}sultan instance restrict${NORMAL}${MAGENTA}"
}

restrict() {
  #############################################################################
  #  Restricts the access to your instance to you only by creating the        #
  #  necessary rules.                                                         #
  #############################################################################
  $sultan firewall deny refresh
  $sultan firewall allow refresh

  if [ "$RESTRICT_INSTANCE" == true ]; then
    public_ip=$(curl -s ifconfig.me)
    success "The instance only communicates with your IP now" "$public_ip"
  else
    warn "The instance accepts requests from any IP now." "0.0.0.0/0"
  fi

  dim "If this is not the expected behavior, consider toggling the instance restriction setting RESTRICT_INSTANCE in your env file."
}

delete() {
  #############################################################################
  # Deletes your instance from GCP.                                           #
  #############################################################################
  message "Deleting your virtual machine from GCP..." "$INSTANCE_NAME"

  $sultan local hosts revert
	$sultan firewall clean

	(gcloud compute instances delete "$INSTANCE_NAME" \
		--quiet \
		--zone="$ZONE" \
		--verbosity "$VERBOSITY" \
		--project "$PROJECT_ID" && success "Your virtual machine has been deleted successfully!") \
	|| message 'No previous instance found'
}

create() {
  #############################################################################
  # Creates an empty instance for you on GCP.                                 #
  #############################################################################

  image="$IMAGE_NAME";
  alive_time="$ALIVE_TIME"
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -i|--image)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          image="$2";
          shift
        fi
        ;;
      -a|--alive-time)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          alive_time="$2";
          shift
        fi
        ;;
      *) error "Unknown parameter passed: $1" "$help_text";;
    esac
    shift
  done

  message "Creating your virtual machine on GCP..." "$INSTANCE_NAME"
  message "Instance will be stopped after: ${BOLD}$alive_time${NORMAL}s"
	cmd=(
	    "gcloud" "compute" "instances" "create" "$INSTANCE_NAME"
	    "--boot-disk-size=$DISK_SIZE"
	    "--boot-disk-type=$BOOT_DISK_TYPE"
	    "--machine-type=$MACHINE_TYPE"
	    "--tags=devstack,http-server,$INSTANCE_TAG"
	    "--zone=$ZONE"
	    "--verbosity=$VERBOSITY"
	    "--project=$PROJECT_ID"
      "--metadata=startup-script=/bin/bash -c '( sleep $alive_time; sudo poweroff -p --no-wall ) &'"
    )


    if [ "$PREEMPTIBLE" == true ]; then
        cmd+=( --preemptible )
    fi

    if [ -n "$image" ]; then
        cmd+=( --image="$image" --image-project="$PROJECT_ID" )
    else
        cmd+=( --image-project=ubuntu-os-cloud --image-family=ubuntu-1804-lts )
    fi

    "${cmd[@]}" || error "Something went wrong while creating your instance."
	success "Your virtual machine has been successfully created!"
}

deploy() {
  #############################################################################
  # Deploys the instance to install required libraries and software.          #
  #############################################################################
    message "Deploying your instance..." "$INSTANCE_NAME"
    # shellcheck disable=SC1090
    ansible-playbook "$sultan_dir"/ansible/devstack.yml \
      -i "$INVENTORY" \
      -e "username=$USER_NAME
          home_dir=$HOME_DIR
          instance_name=$INSTANCE_NAME
          working_directory=$DEVSTACK_WORKSPACE
          git_repo_url=$DEVSTACK_REPO_URL
          openedx_release=$OPENEDX_RELEASE
          git_repo_branch=$DEVSTACK_REPO_BRANCH
          virtual_env_dir=$VIRTUAL_ENV" &> "$SHELL_OUTPUT"
        success "Your virtual machine has been deployed successfully!"
        message "Run ${BOLD}${CYAN}sultan instance provision${NORMAL}${MAGENTA} to start provisioning your devstack."
}

provision() {
  #############################################################################
  # Provisions the devstack on your instance.                                 #
  #############################################################################
	$sultan devstack make requirements
	$sultan devstack make dev.clone
	$sultan devstack make dev.pull
	$sultan devstack make dev.provision

	success "The devstack has been provisioned successfully!"
	message "Run ${BOLD}${CYAN}sultan devstack up${NORMAL}${MAGENTA} to start devstack servers."
}

start() {
  #############################################################################
  # Starts your stopped instance on GCP.                                      #
  #############################################################################
	message "Starting your virtual machine on GCP..." "$INSTANCE_NAME"
	gcloud compute instances start "$INSTANCE_NAME" \
		--zone="$ZONE" \
		--project "$PROJECT_ID"

	$sultan local hosts config
	$sultan local ssh config

	# always restrict the instance after starting it.
	restrict

	success "Your virtual machine has been started successfully!"
}

stop() {
  #############################################################################
  # Stops your instance on GCP, but doesn't delete it.                        #
  #############################################################################
  $sultan devstack stop
  $sultan local hosts revert

	message "Stopping your virtual machine on GCP..." "$INSTANCE_NAME"
	gcloud compute instances stop "$INSTANCE_NAME" \
		--zone="$ZONE" \
		--project "$PROJECT_ID"
	success "Your virtual machine has been stopped successfully!"
}

restart() {
  #############################################################################
  # Restarts your virtual machine on GCP.                                            #
  #############################################################################
	message "Restarting your virtual machine on GCP..."
  $sultan instance stop
  $sultan instance start
}

_full_setup() {
  $sultan local config
  delete
  create --alive-time "${1:-$ALIVE_TIME}"
  restrict
  $sultan local hosts config
  $sultan local ssh config
  deploy
  provision

  success "Your instance has been successfully created!"
}

_image_setup() {
  message "Setting up a new instance from your image..."

  # Clean local env and delete the current GCP instance if any
  $sultan local config
  delete

  create --image "${1:-$IMAGE_NAME}" --alive-time "${2:-$ALIVE_TIME}"

  # Restarts the VM to apply env changes
  $sultan instance restart

  $sultan local hosts config
  $sultan local ssh config

  message "Personalizing your instance..."
  # shellcheck disable=SC1090
  ansible-playbook "$sultan_dir"/ansible/devstack.yml \
  -i "$INVENTORY" \
  --tags "reconfiguration,never"  \
  -e "username=$USER_NAME
      ci_build=$ETC_HOSTS_HACK
      git_repo_url=$DEVSTACK_REPO_URL
      git_repo_branch=$DEVSTACK_REPO_BRANCH
      openedx_release=$OPENEDX_RELEASE
      virtual_env_dir=$VIRTUAL_ENV
      home_dir=$HOME_DIR
      instance_name=$INSTANCE_NAME
      user=$USER_NAME
      working_directory=$DEVSTACK_WORKSPACE" &> "$SHELL_OUTPUT"

  success "Your instance has been successfully created!" "From $IMAGE_NAME"
  message "Run ${BOLD}${CYAN}sultan devstack up${NORMAL}${MAGENTA} to start devstack servers."
}

describe() {
  #############################################################################
  # Describes your virtual machine instance.                                   #
  #############################################################################
  gcloud compute instances describe "$INSTANCE_NAME" \
    --quiet \
    --zone="$ZONE" \
    --verbosity "$VERBOSITY" \
    --project "$PROJECT_ID" \
  || warn "No instance found" "SKIPPING"
}

status() {
  #############################################################################
  # Shows the status of your running machine.                                 #
  #############################################################################
  gcloud compute instances describe "$INSTANCE_NAME" \
    --quiet \
    --zone="$ZONE" \
    --verbosity "$VERBOSITY" \
    --format='value[](status)' \
    --project "$PROJECT_ID" \
  || warn "No instance found" "SKIPPING"
}

setup() {
  full_setup=1
  image="$IMAGE_NAME";
  alive_time="$ALIVE_TIME"

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -i|--image)
        full_setup=0;
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          image="$2";
          shift
        fi
        ;;
      -a|--alive-time)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          alive_time="$2";
          shift
        fi
        ;;
      *) error "Unknown parameter passed: $1" "$help_text";;
    esac
    shift
  done

  if [ "$full_setup" -eq 1 ]; then
    _full_setup "$alive_time"
  else
    _image_setup "$image" "$alive_time"
  fi
}

ip() {
  #############################################################################
  # Gets the external IP of your instance.                                    #
  #############################################################################
  gcloud compute instances describe "$INSTANCE_NAME" \
		--zone="$ZONE" \
		--project="$PROJECT_ID" \
		--format='get(networkInterfaces[0].accessConfigs[0].natIP)'
}

run() {
  #############################################################################
  # SSH into or run commands on your instance.                                  #
  #############################################################################
  ssh -tt devstack "$@"
}

help() {
  # shellcheck disable=SC2059
  printf "$help_text" | less
}

# Print help message if command is not found
if ! type -t "$1" | grep -i function > /dev/null; then
  help
  exit 1
fi

"$@"
