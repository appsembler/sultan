#!/bin/bash

current_dir="$(dirname "$0")"
# shellcheck source=scripts/messaging.sh
source "$current_dir/messaging.sh"

help_text="${NORMAL}An Open edX Remote Devstack Toolkit by Appsembler

${BOLD}${GREEN}firewall${NORMAL}
  Manages the firewall configurations on GCP. Firewall rules are created in
  a sole purpose of restricting access to your instance to your machine only.
  This behavior might block your machine from reaching your instance if your
  IP changes, that could easily happen if your disconnect from and connect
  to the internet back. To solve this issue, clean rule comes handy.

  ${BOLD}USAGE:${NORMAL}
    sultan firewall ( deny [action] | allow [action] | clean )

  ${BOLD}RULES:${NORMAL}
    allow     Manages allow firewall rules.
    deny      Manages deny firewall rules.
    clean     Remove all firewall rules from GCP.

  ${BOLD}ACTIONS:${NORMAL}
    create    Creates a GCP firewall rule defines how your gets accessed.
    delete    Deletes a GCP firewall rule.
    refresh   Refreshes the firewall rule by deleating and recreating it.

  ${BOLD}EXAMPLES:${NORMAL}
    sultan firewall clean
    sultan firewall allow remove
    sultan firewall deny create
    sultan firewall allow refresh
"

_create_deny_firewall() {
  #############################################################################
  # Creates a GCP Firewall's rule to prevent all kind of access to your       #
  # instance.                                                                 #
  #############################################################################

  if [ "$RESTRICT_INSTANCE" == true ]; then
    message "Creating DENY firewall rule in gcp..." "$DENY_FIREWALL"
    (gcloud compute firewall-rules create "$DENY_FIREWALL" \
      --quiet \
      --verbosity "$VERBOSITY" \
      --action=deny \
      --direction=ingress \
      --rules=tcp \
      --source-ranges=0.0.0.0/0 \
      --priority=1000 \
      --target-tags="$INSTANCE_TAG" \
      --project="$PROJECT_ID" && success "DENY firewall has been successfully created!") || warn "Firewall already exists." "SKIPPING"
  else
    message "${BOLD}RESTRICT_INSTANCE${NORMAL} is set to ${YELLOW}false${NORMAL} in your configs"
  fi
}

_delete_deny_firewall()  {
  #############################################################################
  # Deletes the GCP Firewall's rule that prevents accessing your instance     #
  # by all ways.                                                                 #
  #############################################################################
  message "Removing DENY firewall rule from gcp..." "$DENY_FIREWALL"
  (gcloud compute firewall-rules delete "$DENY_FIREWALL" \
    --project="$PROJECT_ID" \
    --verbosity "$VERBOSITY" \
    --quiet && success "DENY firewall has been successfully deleted!") || warn "No previous deny firewall found." "SKIPPING"
}

deny() {
  #############################################################################
  # Manages deny firewall rules.                                              #
  #############################################################################

  if [ "$1" == create ]; then
    _create_deny_firewall
  elif [ "$1" == delete ]; then
    _delete_deny_firewall
  elif [ "$1" == refresh ]; then
    _delete_deny_firewall
    _create_deny_firewall
  	success "Deny rule has been updated on the firewall."
  else
    error "Unknown action passed: $1" "$help_text"
  fi
}

clean() {
  #############################################################################
  # Remove firewall rules from GCP.                                           #
  #############################################################################
  _delete_allow_firewall
  _delete_deny_firewall

  success "Firewall rules have been cleaned from GCP"
}

_create_allow_firewall() {
  #############################################################################
  # Creates a GCP Firewall's rule allowing your IP to access your instance.   #
  #############################################################################

  if [ "$RESTRICT_INSTANCE" == true ]; then
    MY_PUBLIC_IP=$(curl ifconfig.me)
  else
    MY_PUBLIC_IP="0.0.0.0/0"
  fi

    # Processing instance ports
    RULES=$( echo "tcp:$EXPOSED_PORTS" | sed  -e 's/,/,tcp:/g')

	message "Creating ALLOW firewall rule in gcp..." "$ALLOW_FIREWALL:$MY_PUBLIC_IP"
	message "Restricting ports access..." "$EXPOSED_PORTS"
	(gcloud compute firewall-rules create "$ALLOW_FIREWALL" \
		--quiet \
		--verbosity "$VERBOSITY" \
		--action allow \
		--direction ingress \
		--rules "$RULES" \
		--source-ranges "$MY_PUBLIC_IP" \
		--priority 50 \
		--target-tags="$INSTANCE_TAG"\
		--project="$PROJECT_ID" && success "ALLOW firewall has been successfully created!") || warn "Firewall already exists." "SKIPPING"
}

_delete_allow_firewall() {
  #############################################################################
  # Deletes the GCP firewall's rule that allows your IP to access your        #
  # instance.                                                                 #
  #############################################################################

	message "Removing ALLOW firewall rule from gcp..." "$ALLOW_FIREWALL"
	gcloud compute firewall-rules delete "$ALLOW_FIREWALL" \
		--project="$PROJECT_ID" \
		--verbosity "$VERBOSITY" \
		--quiet \
		|| warn "No previous allow firewall found." "SKIPPING"
}

allow() {
  #############################################################################
  # Manages allow firewall rules.                                             #
  #############################################################################
  if [ "$1" == create ]; then
    _create_allow_firewall
  elif [ "$1" == delete ]; then
    _delete_allow_firewall
  elif [ "$1" == refresh ]; then
    _delete_allow_firewall
    _create_allow_firewall
	  success "Allow rule has been updated on the firewall."
  else
    error "Unknown action passed: $1" "$help_text"
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
