include .env*
export $(shell sed 's/=.*//' .env*)

SHELL := /bin/bash
VERSION = 1.0.0
.PHONY: help

help: ## This help message.
	@echo -e "\n\
	Sultan v$(VERSION)\n\
	An Open edX Remote Devstack Toolkit by Appsembler\n\n\n\n\
	Main Targets\n\
	=======================================================================================================\n\n\
	$$(grep -hE '^\S+:.*###' $(MAKEFILE_LIST) | sed -e 's/:.*###\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)\
	\n\n\
	All Targets \n\
	=======================================================================================================\n\n\
	$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)" \
	| less

ve/bin/ansible-playbook: requirements.txt
	@echo Installing project requirements...
	@virtualenv ve
	@ve/bin/pip install -r requirements.txt
	@make local.inventory.config

include targets/*.mk

error:
	@echo ''
	@echo 'An error happened while executing the command you just used!'
	@echo 'While this might be an issue in the tool, we would like you to debug the problem a little bit more using:'
	@echo -e "    * Run \`make environment.debug\` and check if all of your environment variables have the correct value."
	@echo -e "    * Check https://github.com/appsembler/sultan/wiki for a detailed documentation on the configurations."
	@echo -e "\nIf you couldn't identify the real cause of the problem, please submit an issue on https://github.com/appsembler/sultan/issues."

environment.create:  ### Creates a custom environment file for you where you can personalize your instance's default settings.
	@echo Creating \`.env.$(USER_NAME)\` file...
	@[ -f .env.$(USER_NAME) ] && \
		echo ABORTED: \`.env.$(USER_NAME)\` already exists! || \
		sed '/^#/! s/\(.*\)/#\1/g' <.env > .env.$(USER_NAME)

clean:  ## Clean software and directory caches.
	@echo Flush pip packages...
	@rm -rf ve
	@rm dynamic-inventory/gce.ini || echo ''
	@make ve/bin/ansible-playbook

	@echo Flush Ansible cache...
	@. ve/bin/activate; ansible-playbook local.yml --check --flush-cache &> $(ANSIBLE_OUTPUT)

instance.ping: ve/bin/ansible-playbook  ### Performs a ping to your instance.
	@. ve/bin/activate; ansible -i $(INVENTORY) $(INSTANCE_NAME) -m ping

instance.image.create: instance.image.delete instance.stop   ### Creates an image from your instance on GCP.
	@echo Creating a new devstack image on GCP...
	@make NAME=$(IMAGE_NAME) instance.image.create.command

instance.restrict: instance.firewall.deny.refresh instance.firewall.allow.refresh  ### Restricts the access to your instance to you only by creating the necessary rules.
ifeq ($(RESTRICT_INSTANCE),true)
	@echo "You have the only IP that can access the instance now"
else
	@echo 'Skipping as your settings advise not to restricted your instance.'
endif

instance.setup: clean instance.delete instance.create instance.restrict local.hosts.update local.ssh.config instance.deploy devstack.provision  ### Setup a restricted instance for you on GCP contains a provisioned devstack.
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
