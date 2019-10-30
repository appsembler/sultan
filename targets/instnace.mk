
instance.describe: ## Describes your virtual machine instance:
	@gcloud compute instances describe $(INSTANCE_NAME) \
		--quiet \
		--zone=$(ZONE) \
		--verbosity $(VERBOSITY) \
		--project $(PROJECT_ID) \
		|| echo 'No instance found'

instance.describe.%: ## Shows a specific value of your virtual machine's metadata. Some helpful commands might be status, tags, disks, zone, and accessConfigs.
	@gcloud compute instances describe $(INSTANCE_NAME) \
		--quiet \
		--zone=$(ZONE) \
		--verbosity $(VERBOSITY) \
		--project $(PROJECT_ID) \
		--format='value[]($*)' \
		|| echo 'No instance found'

instance.deploy: ve/bin/ansible-playbook  ## Deploys your remote instance and prepare it for devstack provisioning.
	@. ve/bin/activate; ansible-playbook devstack.yml \
		-i $(INVENTORY) \
		-e "instance_name=$(INSTANCE_NAME) working_directory=$(DEVSTACK_WORK_DIR) git_repo_url=$(DEVSTACK_REPO_URL) git_repo_branch=$(DEVSTACK_REPO_BRANCH)"
	@echo Run \`make devstack.provision\` to run the devstack.

devstack.provision:  ## Provisions the devstack on your instance.
	make instance.run command="cd $(DEVSTACK_WORK_DIR)/devstack/ && make dev.provision"
	@echo Run \`make devstack.run\` to run the devstack.

instance.delete: local.hosts.revert instance.firewall.deny.delete instance.firewall.allow.delete  ### Deletes your instance from GCP.
	@echo Removing your instance \($(INSTANCE_NAME)\) from GCP...
	@gcloud compute instances delete $(INSTANCE_NAME) \
		--quiet \
		--zone=$(ZONE) \
		--verbosity $(VERBOSITY) \
		--project $(PROJECT_ID) \
		|| echo 'No previous instance found'

instance.start:  ## Starts your stopped instance on GCP.
	@gcloud compute instances start $(INSTANCE_NAME) \
		--zone=$(ZONE) \
		--project $(PROJECT_ID)
	@make local.hosts.update
	@make local.ssh.config

instance.stop: local.hosts.revert  ## Stops your instance on GCP, but doesn't delete it.
	@echo Stopping your instance \($(INSTANCE_NAME)\) on GCP...
	@gcloud compute instances stop $(INSTANCE_NAME) \
		--zone=$(ZONE) \
		--project $(PROJECT_ID)

instance.create:   ## Creates an empty instance for you on GCP.
	@echo Creating your virtual machine on GCP...
	@gcloud compute instances create $(INSTANCE_NAME) \
		--image-family=ubuntu-1804-lts \
		--image-project=gce-uefi-images \
		--boot-disk-size=$(DISK_SIZE) \
		--machine-type=$(MACHINE_TYPE) \
		--tags=devstack,http-server,$(INSTANCE_TAG) \
		--zone=$(ZONE) \
		--verbosity $(VERBOSITY) \
		--project=$(PROJECT_ID)

instance.run:  ## SSH into or run commands on your instance.

	@ssh -tt devstack "$(command)"

instance.ip:  ## Gets the external IP of your instance.
	@gcloud compute instances describe $(INSTANCE_NAME) \
		--zone=$(ZONE) \
		--project=$(PROJECT_ID) \
		--format='get(networkInterfaces[0].accessConfigs[0].natIP)'
