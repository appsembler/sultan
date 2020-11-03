#!/bin/bash

current_dir="$(dirname "$0")"
source "$current_dir/messaging.sh"

configure_inventory() {
  message "Updating your inventory credentials..." "dynamic-inventory/gce.ini"

  ansible_vars="PROJECT_ID=$PROJECT_ID \
      SERVICE_ACCOUNT_EMAIL=$SERVICE_ACCOUNT_EMAIL \
      SERVICE_KEY_PATH=$SERVICE_KEY_PATH"

	. $ACTIVATE; ansible-playbook local.yml \
		--connection=local -i '127.0.0.1,' --tags inventory -e "$ansible_vars" \
		  > $SHELL_OUTPUT \
		  || throw_error "Something went wrong while configuring your inventory."

	ssh-add $SSH_KEY
	success "Your inventory has been configured successfully!"
}

requirements() {
  #############################################################################
  # Creates env directory and installs the project requirements mentioned in  #
  # requirements.txt file.                                                    #
  #############################################################################

	message "Installing project requirements..."
	touch requirements.txt
	virtualenv -p python3 ve &> $SHELL_OUTPUT
	$PIP install -r requirements.txt&> $SHELL_OUTPUT
  configure_inventory
}

clean() {
  #############################################################################
  # Clean software and directory caches.                                      #
  #############################################################################
	message "Flush pip packages..."
	rm -rf ve
	rm dynamic-inventory/gce.ini || printf '\n'

	# Installing local environment requirements
	requirements

	message "Flushing Ansible cache..."
	. $ACTIVATE; ansible-playbook local.yml --check --flush-cache &> $SHELL_OUTPUT
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
  ./sultan local clean

  if [ $1 == revert ]; then
    message "Reverting made local changes..." "/etc/hosts, ~/.ssh/config"

	  # Check if sudo password is required
	  sudocheck

    . $ACTIVATE; sudo ansible-playbook \
        --connection=local \
        -i '127.0.0.1,' \
        -e "EDX_HOST_NAMES=$EDX_HOST_NAMES)" \
        --tags hosts_revert local.yml > $SHELL_OUTPUT \
      || error "ERROR reverting local changes."

    success "Your local changes have been reverted successfully!"
  elif [ $1 == update ]; then
    message "Updating your hosts records..." "/etc/hosts"

    IP_ADDRESS=$(./sultan instance ip)

	  # Check if sudo password is required
	  sudocheck

    . $ACTIVATE; sudo ansible-playbook \
      --connection=local \
      -i '127.0.0.1,' \
      --tags hosts_update \
      -e "IP_ADDRESS=$IP_ADDRESS EDX_HOST_NAMES=$EDX_HOST_NAMES" local.yml > $SHELL_OUTPUT \
    || error "ERROR configuring hosts records."
    success "Your hosts have been configured successfully!"
  else
    error "Unknown parameter passed: $1"
  fi
}

ssh() {
  if [ $1 == config ]; then
    message "Updating necessary records in SSH related files..." "~/.ssh/config, ~/.ssh/knwon_hosts"
    IP_ADDRESS=$(./sultan instance ip)

    . $ACTIVATE; ansible-playbook local.yml \
        --connection=local \
        -i '127.0.0.1,' \
        --tags ssh_config \
        -e "IP_ADDRESS=$IP_ADDRESS USER=$USER_NAME SSH_KEY=$SSH_KEY" > $SHELL_OUTPUT \
      || error "ERROR configuring SSH connection in your machine."

    ssh-add $SSH_KEY
    success "SSH connection between your machine and the instance has been configured successfully!"
  else
    error "Unknown parameter passed: $1"
  fi
}

"$@"