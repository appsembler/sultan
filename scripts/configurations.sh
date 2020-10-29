#!/bin/sh

current_dir="$(dirname "$0")"
source "$current_dir/messaging.sh"

# Source configurations variables
source configs/.configs
for f in configs/.configs.*; do source $f; done

init() {
  #############################################################################
  # Creates a custom environment file for you where you can personalize your  #
  # instance's default settings.                                              #
  #############################################################################

  force=0
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -f|--force) force=1 ;;
      *) error "Unknown parameter passed: $1" ;;
    esac
    shift
  done

  message "Creating your custom environment file..." ".configs.$USER_NAME"
  if [ -f configs/.configs.$USER_NAME ] && [ $force -eq 0 ]; then
      warn "Configs file '.configs.$USER_NAME' already exists!" "ABORTED"
      exit 1
  else
    # Create a new configs file for your username
    sed '/^#/! s/\(.*\)/#\1/g' <configs/.configs > configs/.configs.$USER_NAME

    # Success message
    success "Your env file has been successfully created."
    message "Make sure to override the following variables before proceeding to the setup:
        * SSH_KEY
        * PROJECT_ID
        * SERVICE_ACCOUNT_EMAIL
        * SERVICE_KEY_PATH"
  fi
}

debug() {
  #############################################################################
  # Prints the values of the environment variables to be used in the make     #
  # command as define in .configs.* files.                                    #
  #############################################################################

  printf "${CYAN}ALLOW_FIREWALL${NORMAL}        %s\n" $ALLOW_FIREWALL
	printf "${CYAN}DENY_FIREWALL${NORMAL}         %s\n" $DENY_FIREWALL
	printf "${CYAN}DEVSTACK_REPO_BRANCH${NORMAL}  %s\n" $DEVSTACK_REPO_BRANCH
	printf "${CYAN}DEVSTACK_REPO_URL${NORMAL}     %s\n" $DEVSTACK_REPO_URL
	printf "${CYAN}DEVSTACK_RUN_COMMAND${NORMAL}  %s\n" $DEVSTACK_RUN_COMMAND
	printf "${CYAN}DEVSTACK_WORKSPACE${NORMAL}    %s\n" $DEVSTACK_WORKSPACE
	printf "${CYAN}DEVSTACK_WORKSPACE${NORMAL}    %s\n" $DEVSTACK_WORKSPACE
	printf "${CYAN}DISK_SIZE${NORMAL}             %s\n" $DISK_SIZE
	printf "${CYAN}EDX_HOST_NAMES${NORMAL}        %s\n" $EDX_HOST_NAMES
	printf "${CYAN}HOST_NAME${NORMAL}             %s\n" $HOST_NAME
	printf "${CYAN}HOSTS_FILE${NORMAL}            %s\n" $HOSTS_FILE
	printf "${CYAN}IMAGE_FAMILY${NORMAL}          %s\n" $IMAGE_FAMILY
	printf "${CYAN}IMAGE_NAME${NORMAL}            %s\n" $IMAGE_NAME
	printf "${CYAN}INSTANCE_NAME${NORMAL}         %s\n" $INSTANCE_NAME
	printf "${CYAN}INSTANCE_TAG${NORMAL}          %s\n" $INSTANCE_TAG
	printf "${CYAN}INVENTORY${NORMAL}             %s\n" $INVENTORY
	printf "${CYAN}MACHINE_TYPE${NORMAL}          %s\n" $MACHINE_TYPE
	printf "${CYAN}MOUNT_DIR${NORMAL}             %s\n" $MOUNT_DIR
	printf "${CYAN}OPENEDX_RELEASE${NORMAL}       %s\n" $OPENEDX_RELEASE
	printf "${CYAN}PROJECT_ID${NORMAL}            %s\n" $PROJECT_ID
	printf "${CYAN}RESTRICT_INSTANCE${NORMAL}     %s\n" $RESTRICT_INSTANCE
	printf "${CYAN}SERVICE_ACCOUNT_EMAIL${NORMAL} %s\n" $SERVICE_ACCOUNT_EMAIL
	printf "${CYAN}SERVICE_KEY_PATH${NORMAL}      %s\n" $SERVICE_KEY_PATH
	printf "${CYAN}SHELL_OUTPUT${NORMAL}          %s\n" $SHELL_OUTPUT
	printf "${CYAN}SSH_KEY${NORMAL}               %s\n" $SSH_KEY
	printf "${CYAN}TMP_DIR${NORMAL}               %s\n" $TMP_DIR
	printf "${CYAN}USER_NAME${NORMAL}             %s\n" $USER_NAME
	printf "${CYAN}VERBOSITY${NORMAL}             %s\n" $VERBOSITY
	printf "${CYAN}VIRTUAL_ENV${NORMAL}           %s\n" $VIRTUAL_ENV
	printf "${CYAN}ZONE${NORMAL}                  %s\n" $ZONE
}

"$@"
