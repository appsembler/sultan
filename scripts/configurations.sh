#!/bin/bash

current_dir="$(dirname "$0")"
# shellcheck source=scripts/messaging.sh
source "$current_dir/messaging.sh"

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
  if [ -f configs/.configs."$USER_NAME" ] && [ $force -eq 0 ]; then
      warn "Configs file '.configs.$USER_NAME' already exists!" "ABORTED"
      exit 1
  else
    # Clean local directory
    ./sultan local clean

    # Create a new configs file for your username
    sed '/^#/! s/\(.*\)/\1/g' <configs/.configs > configs/.configs."$USER_NAME"

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

  printf "${BOLD}${PINK}%-30s${NORMAL}\n" "REQUIRED"
  printf "${YELLOW}%-30s${NORMAL} %-10s\n" "  SSH_KEY" "$SSH_KEY"
  printf "${YELLOW}%-30s${NORMAL} %-10s\n" "  PROJECT_ID" "$PROJECT_ID"
  printf "${YELLOW}%-30s${NORMAL} %-10s\n" "  SERVICE_ACCOUNT_EMAIL" "$SERVICE_ACCOUNT_EMAIL"
  printf "${YELLOW}%-30s${NORMAL} %-10s\n" "  SERVICE_KEY_PATH" "$SERVICE_KEY_PATH"

  printf "\n------------------------------------------------------------------------------------------------\n\n"

  printf "${PURPLE}%-30s${NORMAL} %-10s\n" "DEBUG" "$DEBUG"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  SHELL_OUTPUT" "$SHELL_OUTPUT"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  VERBOSITY" "$VERBOSITY"

  printf "${PURPLE}%-30s${NORMAL}\n" "DEVSTACK"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  DEVSTACK_REPO_BRANCH" "$DEVSTACK_REPO_BRANCH"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  DEVSTACK_REPO_URL" "$DEVSTACK_REPO_URL"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  DEVSTACK_RUN_COMMAND" "$DEVSTACK_RUN_COMMAND"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  DEVSTACK_WORKSPACE" "$DEVSTACK_WORKSPACE"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  DEVSTACK_WORKSPACE" "$DEVSTACK_WORKSPACE"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  EDX_HOST_NAMES" "$EDX_HOST_NAMES"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  OPENEDX_RELEASE" "$OPENEDX_RELEASE"

  printf "${PURPLE}%-30s${NORMAL}\n" "FIREWALL"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  ALLOW_FIREWALL" "$ALLOW_FIREWALL"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  DENY_FIREWALL" "$DENY_FIREWALL"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  RESTRICT_INSTANCE" "$RESTRICT_INSTANCE"

  printf "${PURPLE}%-30s${NORMAL}\n" "Google Cloud Platform"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  PROJECT_ID" "$PROJECT_ID"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  SERVICE_ACCOUNT_EMAIL" "$SERVICE_ACCOUNT_EMAIL"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  SERVICE_KEY_PATH" "$SERVICE_KEY_PATH"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  ZONE" "$ZONE"

  printf "${PURPLE}%-30s${NORMAL}\n" "IMAGE"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  IMAGE_FAMILY" "$IMAGE_FAMILY"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  IMAGE_NAME" "$IMAGE_NAME"

  printf "${PURPLE}%-30s${NORMAL}\n" "INSTANCE"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  DISK_SIZE" "$DISK_SIZE"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  INSTANCE_NAME" "$INSTANCE_NAME"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  INSTANCE_TAG" "$INSTANCE_TAG"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  MACHINE_TYPE" "$MACHINE_TYPE"

  printf "${PURPLE}%-30s${NORMAL}\n" "LOCAL"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  HOSTS_FILE" "$HOSTS_FILE"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  INVENTORY" "$INVENTORY"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  MOUNT_DIR" "$MOUNT_DIR"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  SSH_KEY" "$SSH_KEY"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  TMP_DIR" "$TMP_DIR"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  USER_NAME" "$USER_NAME"
  printf "${CYAN}%-30s${NORMAL} %-10s\n" "  VIRTUAL_ENV" "$VIRTUAL_ENV"

  exit 0
}

"$@"
