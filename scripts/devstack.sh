#!/bin/sh

current_dir="$(dirname "$0")"
source "$current_dir/messaging.sh"

# Source configurations variables
source configs/.configs
for f in configs/.configs.*; do source $f; done

make() {
  #############################################################################
  # Performs a devstack make command on the GCP instance.                     #
  #############################################################################
  ssh -tt devstack "
    cd $DEVSTACK_DIR &&
    source $VIRTUAL_ENV/bin/activate &&
    make DEVSTACK_WORKSPACE=$DEVSTACK_WORKSPACE OPENEDX_RELEASE=$OPENEDX_RELEASE VIRTUAL_ENV=$VIRTUAL_ENV $1"
}

up()  {
  #############################################################################
  # Runs devstack servers.                                                    #
  #############################################################################
  make down
	make dev.pull
	make $DEVSTACK_RUN_COMMAND
	success "The devstack is up and running."
}

unmount() {
  #############################################################################
  # Releases the devstack mount from your machine.                            #
  #############################################################################
  UNMOUNT=$(eval ./sultan instance ip)

  if [ $(uname -s) == Darwin ]; then
    UNMOUNT=diskutil
  else
    UNMOUNT=sudo
  fi

	($UNMOUNT unmount force $MOUNT_DIR && \
		rm -rf $MOUNT_DIR && \
		success "Workspace unmounted successfully.") \
	|| warn "No mount found" "SKIPPING"
}

stop()  {
  #############################################################################
  # Stops and unmounts a devstack servers.                                                   #
  #############################################################################
  unmount
  make stop
	success "Your devstack stopped successfully."
}

mount() {
  #############################################################################
  # Mounts devstack files from your GCP instance onto your local machine.     #
  #############################################################################
  IP_ADDRESS=$(eval ./sultan instance ip)

	mkdir -p $MOUNT_DIR
	message "Mount directory created." $MOUNT_DIR
	sshfs \
	  -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,IdentityFile=$SSH_KEY \
	  $USER_NAME@$IP_ADDRESS:$DEVSTACK_WORKSPACE $MOUNT_DIR
	success "Workspace has been mounted successfully."
}

"$@"
