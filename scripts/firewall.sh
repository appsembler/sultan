#!/bin/sh

current_dir="$(dirname "$0")"
source "$current_dir/messaging.sh"

# Source configurations variables
source configs/.configs
for f in configs/.configs.*; do source $f; done

create_deny_firewall() {
  #############################################################################
  # Creates a GCP Firewall's rule to prevent all kind of access to your       #
  # instance.                                                                 #
  #############################################################################

  if [ $RESTRICT_INSTANCE == true ]; then
    message "Creating DENY firewall rule in gcp..." $DENY_FIREWALL
    (gcloud compute firewall-rules create $DENY_FIREWALL \
      --quiet \
      --verbosity $VERBOSITY \
      --action=deny \
      --direction=ingress \
      --rules=tcp \
      --source-ranges=0.0.0.0/0 \
      --priority=1000 \
      --target-tags=$INSTANCE_TAG \
      --project=$PROJECT_ID && success "DENY firewall has been successfully created!") || warn "Firewall already exists." "SKIPPING"
  else
    message "${BOLD}RESTRICT_INSTANCE${NORMAL} is set to ${YELLOW}false${NORMAL} in your configs"
  fi
}

delete_deny_firewall()  {
  #############################################################################
  # Deletes the GCP Firewall's rule that prevents accessing your instance     #
  # by all ways.                                                                 #
  #############################################################################
  message "Removing DENY firewall rule from gcp..." $DENY_FIREWALL
  (gcloud compute firewall-rules delete $DENY_FIREWALL \
    --project=$PROJECT_ID \
    --verbosity $VERBOSITY \
    --quiet && success "DENY firewall has been successfully deleted!") || warn "No previous deny firewall found." "SKIPPING"
}

deny() {
  #############################################################################
  # Manages deny firewall rules.                                              #
  #############################################################################

  if [ $1 == create ]; then
    create_deny_firewall
  elif [ $1 == delete ]; then
    delete_deny_firewall
  elif [ $1 == refresh ]; then
    delete_deny_firewall
    create_deny_firewall
  	success "Deny rule has been updated on the firewall."
  else
    error "Unknown parameter passed: $1"
  fi
}

clean() {
  #############################################################################
  # Remove firewall rules from GCP.                                           #
  #############################################################################
  delete_allow_firewall
  delete_deny_firewall

  success "Firewall rules has been cleaned from GCP"
}

create_allow_firewall() {
  #############################################################################
  # Creates a GCP Firewall's rule allowing your IP to access your instance.   #
  #############################################################################

  if [ $RESTRICT_INSTANCE == true ]; then
    MY_PUBLIC_IP=$(curl ifconfig.me)
  else
    MY_PUBLIC_IP="0.0.0.0/0"
  fi

	message "Creating ALLOW firewall rule in gcp..." "$ALLOW_FIREWALL:$MY_PUBLIC_IP"
	(gcloud compute firewall-rules create $ALLOW_FIREWALL \
		--quiet \
		--verbosity $VERBOSITY \
		--action allow \
		--direction ingress \
		--rules tcp \
		--source-ranges $MY_PUBLIC_IP \
		--priority 50 \
		--target-tags=$INSTANCE_TAG\
		--project=$PROJECT_ID && success "ALLOW firewall has been successfully created!") || warn "Firewall already exists." "SKIPPING"
}

delete_allow_firewall() {
  #############################################################################
  # Deletes the GCP Firewall's rule that allows your IP to access your        #
  # instance.                                                                 #
  #############################################################################

	message "Removing ALLOW firewall rule from gcp..." $ALLOW_FIREWALL
	gcloud compute firewall-rules delete $ALLOW_FIREWALL \
		--project=$PROJECT_ID \
		--verbosity $VERBOSITY \
		--quiet \
		|| warn "No previous allow firewall found." "SKIPPING"
}

allow() {
  #############################################################################
  # Manages allow firewall rules.                                             #
  #############################################################################
  if [ $1 == create ]; then
    create_allow_firewall
  elif [ $1 == delete ]; then
    delete_allow_firewall
  elif [ $1 == refresh ]; then
    delete_allow_firewall
    create_allow_firewall
	  success "Allow rule has been updated on the firewall."
  else
    error "Unknown parameter passed: $1"
  fi
}

"$@"
