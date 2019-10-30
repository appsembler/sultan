devstack.make:  ## Perfoms a make command on your instance.
	@make instance.run command="(cd $(DEVSTACK_WORK_DIR)/devstack && make $(target))"

devstack.run:  ### Runs devstack servers.
	make instance.run command="cd $(DEVSTACK_WORK_DIR)/devstack && make $(DEVSTACK_RUN_COMMAND)"

devstack.stop: devstack.unmount  ### Stops and unmounts a devstack servers.
	@make devstack.make target=stop

devstack.mount:  ### Mounts the devstack from your instance onto your machine.
	$(eval IP_ADDRESS := $(shell make instance.ip))

	@mkdir -p $(MOUNT_DIR)
	@echo "Mount directory created: " $(MOUNT_DIR)
	@sshfs \
		-o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,IdentityFile=$(SSH_KEY) \
		$(USER_NAME)@$(IP_ADDRESS):$(DEVSTACK_WORK_DIR) \
		$(MOUNT_DIR)
	@echo "Workspace has been mounted successfully."

devstack.unmount: ## Releases the devstack mount from your machine.
ifeq ($(shell uname -s),Darwin)
	@diskutil unmount force $(MOUNT_DIR) || echo  'No mount found'
else
	@sudo unmount force $(MOUNT_DIR) || echo  'No mount found'
endif

	@rm -rf $(MOUNT_DIR)
