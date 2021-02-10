#!/bin/bash

current_dir="$(dirname "$0")"
sultan_dir="$(dirname "$current_dir")"
sultan="$sultan_dir"/sultan

# shellcheck source=scripts/messaging.sh
source "$current_dir/messaging.sh"

help_text="${NORMAL}An Open edX Remote Devstack Toolkit by Appsembler

${BOLD}${GREEN}local${NORMAL}
  Takes care of configuring your local machine to be able communicate with
  the remote one.

  ${BOLD}USAGE:${NORMAL}
    sultan local <argument> [OPTION]

  ${BOLD}ARGUMENTS:${NORMAL}
    config        Cleans software and directory caches, and installs the
                  project requirements mentioned in requirements.txt file.
    hosts         Updates your hosts file by adding/removing the necessary
                  hosts to it.
    ssh           Configures Sultan's SSH rules and connection on your
                  machine.

  ${BOLD}OPTIONS:${NORMAL}
    revert        Reverts the changes made locally and restore all modified
                  files to their original state.
    update        Apply the required changes on local files.

  ${BOLD}EXAMPLES:${NORMAL}
    sultan local config
    sultan local hosts revert
    sultan local ssh config
"


configure_inventory() {
  message "Updating your inventory credentials..." "$INVENTORY_CONFIGS_DIR/gce.ini"

  ansible_vars="PROJECT_ID=$PROJECT_ID \
      SERVICE_ACCOUNT_EMAIL=$SERVICE_ACCOUNT_EMAIL \
      inventory_configs_dir=$INVENTORY_CONFIGS_DIR \
      inventory_target=$INVENTORY \
      ZONE=$ZONE \
      SERVICE_KEY_PATH=$SERVICE_KEY_PATH"

  # shellcheck disable=SC1090
  ansible-playbook "$sultan_dir"/ansible/local.yml \
				  --connection=local \
				  -i '127.0.0.1,' \
				  --tags inventory \
				  -e "$ansible_vars" > "$SHELL_OUTPUT" \
      || error "Something went wrong while configuring your inventory."

  ssh-add "$SSH_KEY"
  success "Your inventory has been configured successfully!"
}

config() {
  #############################################################################
  # Cleans software and directory caches, and installs the project            #
  # requirements mentioned in requirements.txt file.                         #
  #############################################################################
	message "Remove sultan files..." "$SULTAN_HOME"
	rm -rf "$SULTAN_HOME"

	message "Installing project requirements..." "$SULTAN_ENV"
	pip install -r "$sultan_dir"/requirements.txt &> "$SHELL_OUTPUT"

	configure_inventory
}

sudocheck ()  {
  #############################################################################
  # Checks whether a sudo password is required or not.                        #
  #############################################################################

  if ! sudo -n true 2>/dev/null; then
		warn "Please enter your sudo password..."; \
  fi
}

hosts() {
  #############################################################################
  # Updates your hosts file by adding/removing the necessary hosts to it.     #
  #############################################################################
  if [ "$1" == revert ]; then
      message "Reverting made local changes..." "/etc/hosts, ~/.ssh/config"

      # Check if sudo password is required
      sudocheck

      ansible-playbook \
           --connection=local \
           -i '127.0.0.1,' \
           -e "EDX_HOST_NAMES=$EDX_HOST_NAMES" \
           --tags hosts_revert "$sultan_dir"/ansible/local.yml | sudo tee "$SHELL_OUTPUT" > /dev/null \
          || error "ERROR reverting local changes."

    success "Your local changes have been reverted successfully!"
  elif [ "$1" == config ]; then
    message "Updating your hosts records..." "/etc/hosts"

    IP_ADDRESS=$("$sultan" instance ip)

    # Check if sudo password is required
    sudocheck

    # shellcheck disable=SC2024
    sudo ansible-playbook \
         --connection=local \
         -i '127.0.0.1,' \
         --tags hosts_update \
         -e "IP_ADDRESS=$IP_ADDRESS EDX_HOST_NAMES=$EDX_HOST_NAMES" "$sultan_dir"/ansible/local.yml > "$SHELL_OUTPUT" \
        || error "ERROR configuring hosts records."
    success "Your hosts have been configured successfully!"
  else
    error "Unknown parameter passed: $1" "$help_text"
  fi
}

ssh() {
  #############################################################################
  # Configures Sultan's SSH rules and connection on your machine.             #
  #############################################################################

  if [ "$1" == config ]; then
    message "Updating necessary records in SSH related files..." "$HOME/.ssh/config, $HOME/.ssh/known_hosts"
    IP_ADDRESS=$("$sultan" instance ip)

    # shellcheck disable=SC1090
    ansible-playbook "$sultan_dir"/ansible/local.yml \
        --connection=local \
        -i '127.0.0.1,' \
        --tags ssh_config \
        -e "IP_ADDRESS=$IP_ADDRESS USER=$USER_NAME SSH_KEY=$SSH_KEY" > "$SHELL_OUTPUT" \
      || error "ERROR configuring SSH connection in your machine."

    ssh-add "$SSH_KEY"
    success "SSH connection between your machine and the instance has been configured successfully!"
  else
    error "Unknown parameter passed: $1" "$help_text"
  fi
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
