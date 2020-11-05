
instance.describe: ## Describes your virtual machine instance:
	@gcloud compute instances describe $(INSTANCE_NAME) \
		--quiet \
		--zone=$(ZONE) \
		--verbosity $(VERBOSITY) \
		--project $(PROJECT_ID) \
		|| echo -e "${yellow}No instance found${normal}    (SKIPPING)"

instance.describe.%: ## Shows a specific value of your virtual machine's metadata. Some helpful commands might be status, tags, disks, zone, and accessConfigs.
	@gcloud compute instances describe $(INSTANCE_NAME) \
		--quiet \
		--zone=$(ZONE) \
		--verbosity $(VERBOSITY) \
		--project $(PROJECT_ID) \
		--format='value[]($*)' \
		|| echo -e "${yellow}No instance found${normal}    (SKIPPING)"

instance.deploy: ve/bin/ansible-playbook  ## Deploys your remote instance and prepare it for devstack provisioning.
	@echo -e "Deploying your instance..."
	@. ve/bin/activate; ansible-playbook devstack.yml \
		-i $(INVENTORY) \
		-e "instance_name=$(INSTANCE_NAME) working_directory=$(DEVSTACK_WORKSPACE) git_repo_url=$(DEVSTACK_REPO_URL) openedx_release=$(OPENEDX_RELEASE) git_repo_branch=$(DEVSTACK_REPO_BRANCH) virtual_env_dir=$(VIRTUAL_ENV)" &> $(SHELL_OUTPUT)
	@echo -e "${green}Your virtual machine has been deployed successfully!${normal}"
	@echo -e "Run ${cyan}${underline}make devstack.provision${normal} to start provisioning your devstack."

devstack.provision:  ## Provisions the devstack on your instance.
	@make devstack.make target=requirements
	@make devstack.make target=dev.clone
	@make devstack.make target=dev.checkout
	@make devstack.make target=dev.provision

	@echo -e "${green}The devstack has been provisioned successfully!${normal}"
	@echo -e "Run ${cyan}${underline}make devstack.run${normal} to start devstack servers."

instance.delete: local.hosts.revert instance.firewall.deny.delete instance.firewall.allow.delete  ### Deletes your instance from GCP.
	@echo -e "Deleting your virtual machine from GCP...   ${dim}($(INSTANCE_NAME))${normal}"
	@(gcloud compute instances delete $(INSTANCE_NAME) \
		--quiet \
		--zone=$(ZONE) \
		--verbosity $(VERBOSITY) \
		--project $(PROJECT_ID) && echo -e "${green}Your virtual machine has been deleted successfully!${normal}") \
	|| echo 'No previous instance found'

instance.start:  ## Starts your stopped instance on GCP.
	@echo -e "Starting your virtual machine on GCP...   ${dim}($(INSTANCE_NAME))${normal}"
	@gcloud compute instances start $(INSTANCE_NAME) \
		--zone=$(ZONE) \
		--project $(PROJECT_ID)
	@make local.hosts.update
	@make local.hosts.update
	@make local.ssh.config
	@echo -e "${green}Your virtual machine has been started successfully!${normal}"

instance.stop: local.hosts.revert  ## Stops your instance on GCP, but doesn't delete it.
	@echo -e "Stopping your virtual machine on GCP...   ${dim}($(INSTANCE_NAME))${normal}"
	@gcloud compute instances stop $(INSTANCE_NAME) \
		--zone=$(ZONE) \
		--project $(PROJECT_ID)
	@echo -e "${green}Your virtual machine has been stopped successfully!${normal}"

instance.create:   ## Creates an empty instance for you on GCP.
	@echo -e "Creating your virtual machine on GCP...   ${dim}($(INSTANCE_NAME))${normal}"
	@gcloud compute instances create $(INSTANCE_NAME) \
		--image-family=ubuntu-1804-lts \
		--image-project=gce-uefi-images \
		--boot-disk-size=$(DISK_SIZE) \
		--machine-type=$(MACHINE_TYPE) \
		--tags=devstack,http-server,$(INSTANCE_TAG) \
		--zone=$(ZONE) \
		--verbosity=$(VERBOSITY) \
		--project=$(PROJECT_ID)
	@echo -e "${green}Your virtual machine has been successfully created!${normal}"

instance.run:  ## SSH into or run commands on your instance.
	@ssh -tt devstack "$(command)"

instance.ip:  ## Gets the external IP of your instance.
	@gcloud compute instances describe $(INSTANCE_NAME) \
		--zone=$(ZONE) \
		--project=$(PROJECT_ID) \
		--format='get(networkInterfaces[0].accessConfigs[0].natIP)'
