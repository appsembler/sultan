devstack.make:  ## Performs a make command on your instance.
	@make instance.run command="(cd $(DEVSTACK_DIR) \
		&& source $(VIRTUAL_ENV)/bin/activate \
		&& make DEVSTACK_WORKSPACE=$(DEVSTACK_WORKSPACE) \
		   OPENEDX_RELEASE=$(OPENEDX_RELEASE) \
		   VIRTUAL_ENV=$(VIRTUAL_ENV) \
		$(target))"

devstack.run:  ### Runs devstack servers.
	@make devstack.make target=down
	@make devstack.make target=dev.pull
	@make devstack.make target=$(DEVSTACK_RUN_COMMAND)
	@echo -e "${green}The devstack is up and running.${normal}"

devstack.stop: devstack.unmount  ### Stops and unmounts a devstack servers.
	@make devstack.make target=stop
	@echo -e "${green}Your devstack stopped successfully.${normal}"

devstack.mount:  ### Mounts the devstack from your instance onto your machine.
	$(eval IP_ADDRESS := $(shell make instance.ip))

	@mkdir -p $(MOUNT_DIR)
	@echo -e "${bold}Mount directory created${normal}.    ${dim}($(MOUNT_DIR))${normal}"
	@sshfs \
		-o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,IdentityFile=$(SSH_KEY) \
		$(USER_NAME)@$(IP_ADDRESS):$(DEVSTACK_WORKSPACE) \
		$(MOUNT_DIR)
	@echo -e "${green}Workspace has been mounted successfully.${normal}"

devstack.unmount: ## Releases the devstack mount from your machine.
	$(eval UNMOUNT := $(shell make instance.ip))

ifeq ($(shell uname -s),Darwin)
	$(eval UNMOUNT := diskutil)
else
	$(eval UNMOUNT := sudo)
endif

	@($(UNMOUNT) unmount force $(MOUNT_DIR) && \
		rm -rf $(MOUNT_DIR) && \
		echo -e "${green}Workspace unmounted successfully.${normal}") \
	|| echo -e "${yellow}No mount found${normal}    (SKIPPING)"
