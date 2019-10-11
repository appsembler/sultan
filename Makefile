include .env*
export $(shell sed 's/=.*//' .env*)

SHELL := /bin/bash
.PHONY: help


help: ## This help message
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | \
		sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"

environment.display:  ## Prints the values of the environemnt variables to be used in the make command as define in .env.* files
	@echo SSH_KEY = $(SSH_KEY)
	@echo PROJECT_ID = $(PROJECT_ID)
	@echo USER_NAME = $(USER_NAME)
	@echo HOST_NAME = $(HOST_NAME)
	@echo INSTANCE_NAME = $(INSTANCE_NAME)
	@echo INSTANCE_TAG = $(INSTANCE_TAG)
	@echo IMAGE_NAME = $(IMAGE_NAME)
	@echo DENY_FIREWALL = $(DENY_FIREWALL)
	@echo ALLOW_FIREWALL = $(ALLOW_FIREWALL)
	@echo DISK_SIZE = $(DISK_SIZE)
	@echo MACHINE_TYPE = $(MACHINE_TYPE)
	@echo ZONE = $(ZONE)
	@echo INVENTORY = $(INVENTORY)
	@echo TMP_DIR = $(TMP_DIR)
	@echo MOUNT_DIR = $(MOUNT_DIR)
	@echo HOSTS_FILE = $(HOSTS_FILE)
	@echo TAHOE_HOST_NAME = $(TAHOE_HOST_NAME)
	@echo VERBOSITY = $(VERBOSITY)
	@echo ANSIBLE_OUTPUT = $(ANSIBLE_OUTPUT)
	@echo DEVSTACK_WORK_DIR = $(DEVSTACK_WORK_DIR)
	@echo IMAGE_FAMILY = $(IMAGE_FAMILY)

environment.create:
	@echo Creating \`.env.$(USER_NAME)\` file...
	@[ -f .env.$(USER_NAME) ] && \
		echo ERROR: \`.env.$(USER_NAME)\` already exists! || \
		sed '/^#/! s/\(.*\)/#\1/g' <.env > .env.$(USER_NAME)

ve/bin/ansible-playbook: requirements.txt
	@echo Installing project requirements...
	@virtualenv ve
	@ve/bin/pip install -r requirements.txt

clean:  ## Clean software and directory caches
	@echo Flush pip packages...
	@rm -rf ve
	@make ve/bin/ansible-playbook

	@echo Flush Ansible cache...
	@. ve/bin/activate; ansible-playbook local.yml --check --flush-cache &> $(ANSIBLE_OUTPUT)

instance.ping: ve/bin/ansible-playbook  ## Performs a ping to your instance.
	@. ve/bin/activate; ansible -i $(INVENTORY) $(INSTANCE_NAME) -m ping

instance.deploy: ve/bin/ansible-playbook  ## Deploys your remote instance and prepare it for devstack provisioning.
	@. ve/bin/activate; ansible-playbook devstack.yml \
		-i $(INVENTORY) \
		-e "instance_name=$(INSTANCE_NAME)"
	@echo Run \`make devstack.provision\` to run the devstack.

devstack.provision:  ## Provisions the devstack on your instance.
	make instance.run command="cd $(DEVSTACK_WORK_DIR)/devstack/ && make dev.provision"
	@echo Run \`make devstack.run\` to run the devstack.

instance.delete: local.hosts.revert instance.firewall.deny.delete instance.firewall.allow.delete  ## Deletes your instance from GCP.
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

instance.image.delete.command:
	@echo Removing $(NAME) image from GCP...
	@gcloud compute images delete $(NAME) \
		--project=$(PROJECT_ID) \
		--verbosity $(VERBOSITY) \
		--quiet \
		|| echo 'No previous image found'

instance.image.delete:   ## Deletes your image from GCP.
	@make NAME=$(IMAGE_NAME) instance.image.delete.command

instance.image.master.delete:
	@make NAME=$(IMAGE_FAMILY) instance.image.delete.command

instance.image.create.command:
	@gcloud beta compute images create $(NAME) \
		--source-disk=$(INSTANCE_NAME) \
		--source-disk-zone=$(ZONE) \
		--family=$(IMAGE_FAMILY) \
		--labels=user=$(INSTANCE_NAME) \
		--project=$(PROJECT_ID)

instance.image.create: instance.image.delete instance.stop   ## Creates an image from your instance on GCP.
	@echo Create a new image for you on GCP...
	@make NAME=$(IMAGE_NAME) instance.image.create.command

instance.image.master.create: instance.stop instance.image.master.delete  ## Creates a master image from your instance on GCP.
	@echo Create a new master devstack image on GCP...
	@make NAME=$(IMAGE_FAMILY) instance.image.create.command

instance.firewall.deny.delete:   ## Deletes the GCP Firewall's rule that prevents accessing your instance by all ways.
	@echo Removing DENY firewall rule from gcp...
	@gcloud compute firewall-rules delete $(DENY_FIREWALL) \
		--project=$(PROJECT_ID) \
		--verbosity $(VERBOSITY) \
		--quiet \
		|| echo 'No previous deny firewall found'

instance.firewall.deny.create:  ## Creates a GCP Firewall's rule to prevent all kind of access to your instance.
	@echo Creating DENY firewall rule in gcp...
	@gcloud compute firewall-rules create $(DENY_FIREWALL) \
		--action=deny \
		--direction=ingress \
		--rules=tcp \
		--source-ranges=0.0.0.0/0 \
		--priority=1000 \
		--target-tags=$(INSTANCE_TAG) \
		--project=$(PROJECT_ID)

instance.firewall.allow.delete:  ## Deletes the GCP Firewall's rule that allows your IP to access your instance.
	@echo Removing ALLOW firewall rule from gcp...
	@gcloud compute firewall-rules delete $(ALLOW_FIREWALL) \
		--project=$(PROJECT_ID) \
		--verbosity $(VERBOSITY) \
		--quiet \
		|| echo 'No previous allow firewall found'

instance.firewall.allow.create:  ## Creates a GCP Firewall's rule allowing your IP to access your instance.
	$(eval MY_PUBLIC_IP := $(shell curl ifconfig.me))

	@echo Creating ALLOW firewall rule in gcp...
	@gcloud compute firewall-rules create $(ALLOW_FIREWALL) \
		--action allow \
		--direction ingress \
		--rules tcp \
		--source-ranges $(MY_PUBLIC_IP) \
		--priority 50 \
		--target-tags=$(INSTANCE_TAG)\
		--project=$(PROJECT_ID)

instance.firewall.deny.refresh: instance.firewall.deny.delete instance.firewall.deny.create  ## Refreshes the deny rule on GCP Firewall by deleting the old rule and creating a new one.
	@echo "Deny rule has been updated on the firewall."

instance.firewall.allow.refresh: instance.firewall.allow.delete instance.firewall.allow.create  ## Refreshes the allow rule on GCP Firewall by deleting the old rule and creating a new one.
	@echo "Allow rule has been updated on the firewall."

instance.restrict: instance.firewall.deny.refresh instance.firewall.allow.refresh  ## Restricts the access to your instance to you only by creating the necessary rules.
	@echo "You have the only IP that can access the instance now"

instance.setup: clean instance.delete instance.create instance.restrict local.hosts.update local.ssh.config instance.deploy devstack.provision  ## Setup a restricted instance for you on GCP contains a provisioned devstack.
	@echo "Your instance created successfully"

instance.setup.image: clean instance.delete ## Setup a restricted instance for you on GCP (contains a devstack).
	@echo Setting up a new instance from your image...
	@gcloud compute instances create $(INSTANCE_NAME) \
		--image=$(IMAGE_NAME) \
		--image-project=$(PROJECT_ID) \
		--boot-disk-size=$(DISK_SIZE) \
		--machine-type=$(MACHINE_TYPE) \
		--tags=devstack,http-server,$(INSTANCE_TAG) \
		--zone=$(ZONE) \
		--project=$(PROJECT_ID)

	@make instance.restrict
	@make local.hosts.update
	@make local.ssh.config
	@echo "Your instance created successfully from " $(IMAGE_NAME)
	@echo "Run 'make devstack.run' to start the servers"

instance.setup.image.master: clean instance.delete ## Setup a restricted instance from the master image.
	@echo Setting up a new instance from the master image...
	@gcloud compute instances create $(INSTANCE_NAME) \
		--image=$(IMAGE_FAMILY) \
		--image-project=$(PROJECT_ID) \
		--boot-disk-size=$(DISK_SIZE) \
		--machine-type=$(MACHINE_TYPE) \
		--tags=devstack,http-server,$(INSTANCE_TAG) \
		--zone=$(ZONE) \
		--project=$(PROJECT_ID)

	@make instance.restrict
	@make local.hosts.update
	@make local.ssh.config
	@echo "Your instance created successfully from " $(IMAGE_NAME)
	@echo "Run 'make devstack.run' to start the servers"

instance.run:  ## SSH into or run commands on your instance.

	@ssh -tt devstack "$(command)"

instance.ip:  ## Gets the external IP of your instance.
	@gcloud compute instances describe $(INSTANCE_NAME) \
		--zone=$(ZONE) \
		--project=$(PROJECT_ID) \
		--format='get(networkInterfaces[0].accessConfigs[0].natIP)'

local.ssh.config: ve/bin/ansible-playbook
	@echo Updating ~/.ssh/config file ...
	$(eval IP_ADDRESS := $(shell make instance.ip))
	@. ve/bin/activate; ansible-playbook local.yml \
		--connection=local \
		-i '127.0.0.1,' \
		--tags ssh_config \
		-e "IP_ADDRESS=$(IP_ADDRESS) USER=$(USER_NAME) SSH_KEY=$(SSH_KEY)" > $(ANSIBLE_OUTPUT)
	@ssh-add $(SSH_KEY)

local.hosts.update: ve/bin/ansible-playbook  ## Updates your hosts file by adding the necessary hosts to it.
	@echo Updating /etc/hosts file ...

	$(eval IP_ADDRESS := $(shell make instance.ip))
	@. ve/bin/activate; sudo ansible-playbook --connection=local -i '127.0.0.1,' --tags hosts_update -e "IP_ADDRESS=$(IP_ADDRESS) TAHOE_HOST_NAME=$(TAHOE_HOST_NAME)" local.yml > $(ANSIBLE_OUTPUT)

local.hosts.revert: ve/bin/ansible-playbook  ## Updates your hosts file by removing the added hosts from it.
	@echo Reverting changes made on /etc/hosts file ...
	@echo Your local host sudo password might be required.
	@. ve/bin/activate; sudo ansible-playbook --connection=local -i '127.0.0.1,' --tags hosts_revert local.yml > $(ANSIBLE_OUTPUT)

git:  ## Runs git commands against your remote devstack
	@make instance.run command="(cd $(DEVSTACK_WORK_DIR)/$(repo) && git $(command))"

devstack.make:  ## Perfoms a make command on your instance.
	@make instance.run command="(cd $(DEVSTACK_WORK_DIR)/devstack && make $(target))"

devstack.run:  ## Runs devstack servers.
	@make instance.run command="cd $(DEVSTACK_WORK_DIR)/devstack && make HOST=$(TAHOE_HOST_NAME) tahoe.up.full"

devstack.stop:  ## Stops devstack servers.
	@make devstack.make target=stop

devstack.mount:  ## Mounts the devstack from your instance onto your machine.
	$(eval IP_ADDRESS := $(shell make instance.ip))

	@mkdir -p $(MOUNT_DIR)
	@echo "Mount directory created: " $(MOUNT_DIR)
	@sshfs \
		-o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,IdentityFile=$(SSH_KEY) \
		$(USER_NAME)@$(IP_ADDRESS):/home/$(USER_NAME)/work/tahoe-hawthorn \
		$(MOUNT_DIR)

devstack.unmount: ## Releases the devstack mount from your machine.
ifeq ($(shell uname -s),Darwin)
	@diskutil unmount force $(MOUNT_DIR)
else
	@sudo unmount force $(MOUNT_DIR)
endif

	@rm -rf $(MOUNT_DIR)
