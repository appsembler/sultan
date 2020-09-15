include $(sort $(wildcard .configs*))
export $(shell sed 's/=.*//' .configs*)

SHELL := /bin/bash
VERSION = 1.0.0
.PHONY: help

bold = \033[1m
inverted = \033[7m
underline = \033[4m
normal = \033[0m

cyan = \033[36m
dim = \033[90m
green = \033[92m
red = \033[31m
redbold = \033[1;31m
magenta = \033[35m
yellow = \033[33m

help: ## This help message.
	@echo -e "\n\
	Sultan ${cyan}v$(VERSION)${noraml}\n\
	An Open edX Remote Devstack Toolkit by Appsembler\n\n\n\n\
	${bold}Main Targets${normal}\n\
	=======================================================================================================\n\n\
	$$(grep -hE '^\S+:.*###' $(MAKEFILE_LIST) | sed -e 's/:.*###\s*/:/' -e 's/^\(.\+\):\(.*\)/\1:\2/' | column -c2 -t -s :)\
	\n\n\
	${bold}All Targets${normal} \n\
	=======================================================================================================\n\n\
	$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\1:\2/' | column -c2 -t -s :)" \
	| less

ve/bin/ansible-playbook: requirements.txt
	@echo Installing project requirements...
	@virtualenv ve &> $(SHELL_OUTPUT)
	@ve/bin/pip install -r requirements.txt &> $(SHELL_OUTPUT)
	@make local.inventory.config

include targets/*.mk

error:
	@echo ''
	@echo -e "${magenta}An error happened while executing the command you just used!"
	@echo -e "While this might be an issue with the tool, we would like you to do a little bit more debugging:"
	@echo -e "    * Run ${underline}${cyan}make config.debug${normal}${magenta} and check if all of your environment variables hold the correct values."
	@echo -e "    * Toggle the verbosity settings (${bold}VERBOSITY${normal}${magenta}, and ${bold}SHELL_OUTPUT${normal}${magenta}) in your env file. Follow instructions in the comments above  of them for more details."
	@echo -e "    * Check https://github.com/appsembler/sultan/wiki for a detailed documentation on the configuration process."
	@echo -e "\nIf you couldn't identify the cause of the problem, please submit an issue on https://github.com/appsembler/sultan/issues.${normal}"

config.init:  ### Creates a custom environment file for you where you can personalize your instance's default settings.
	@echo -e "Creating your custom environment file...    ${dim}(.configs.$(USER_NAME))${normal}"
	@[ -f .configs.$(USER_NAME) ] && \
		echo -e "${yellow}The file \${bold}.configs.$(USER_NAME)\${normal}${yellow} already exists! ${bold}(ABORTED)${normal}" || \
		(sed '/^#/! s/\(.*\)/#\1/g' <.configs > .configs.$(USER_NAME) && \
		 echo -e "${green}Your env file has been successfully created.${normal}" &&\
		 echo -e "Make sure to override the following variables before proceeding to the setup:" && \
		 echo -e "    * SSH_KEY" && \
		 echo -e "    * PROJECT_ID" && \
		 echo -e "    * SERVICE_ACCOUNT_EMAIL" && \
		 echo -e "    * SERVICE_KEY_PATH" \
		 )

clean:  ## Clean software and directory caches.
	@echo Flush pip packages...
	@rm -rf ve
	@rm dynamic-inventory/gce.ini || echo ''
	@make ve/bin/ansible-playbook

	@echo Flush Ansible cache...
	@. ve/bin/activate; ansible-playbook local.yml --check --flush-cache &> $(SHELL_OUTPUT)

instance.ping: ve/bin/ansible-playbook  ### Performs a ping to your instance.
	@. ve/bin/activate; ansible -i $(INVENTORY) $(INSTANCE_NAME) -m ping \
		|| (echo -e "\n${redbold}ERROR${red} Unable to ping instance!${normal}\n${bold}This might caused by one of the following reasons:${normal}\n\
	    * The instance is not set up yet. To set up an instance run ${underline}${cyan}make instance.setup${normal}.\n\
	    * The instance was stopped. Check the status of your instance using ${underline}${cyan}make instance.describe.status${normal} and start it by running ${underline}${cyan}make instance.start${normal}.\n\
	    * The instance might have been restricted under a previous IP of yours. To allow your current IP from accessing the instance run ${underline}${cyan}make instance.restrict${normal}."; \
	    make error)

image.create: instance.stop image.delete   ### Creates an image from your instance on GCP.
	@echo "Creating a new devstack image from your GCP instance...    ${dim}($(IMAGE_NAME))${normal}"
	@make NAME=$(IMAGE_NAME) image.create.command
	@echo -e "${green}Your image has been successfully created${normal}"

instance.restrict: instance.firewall.deny.refresh instance.firewall.allow.refresh  ### Restricts the access to your instance to you only by creating the necessary rules.
ifeq ($(RESTRICT_INSTANCE),true)
	$(eval MY_PUBLIC_IP := $(shell curl -s ifconfig.me))
	@echo -e "${green}The instance only communicates with your IP now${normal}    ${dim}($(MY_PUBLIC_IP))${normal}"
else
	@echo -e "\n${yellow}The instance accepts requests from any IP now.${normal}    ${dim}(0.0.0.0/0)${normal}"
endif
	@echo -e "If this is not the expected behavior, consider toggling the instance restriction setting ${bold}RESTRICT_INSTANCE${normal} in your env file."

instance.setup: clean instance.delete instance.create instance.restrict local.hosts.update local.ssh.config instance.deploy devstack.provision  ### Setup a restricted instance for you on GCP contains a provisioned devstack.
	@echo -e "${green}Your instance has been successfully created!${normal}"

instance.setup.image: clean instance.delete ## Setup a restricted instance from an already created image for you on GCP (contains a devstack).
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
	@echo -e "${green}Your instance has been successfully created!${normal} (From $(IMAGE_NAME))"
	@echo -e "Run ${cyan}${underline}make instance.start${normal} and then ${cyan}${underline}make devstack.run${normal} to start devstack servers."

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
	@echo -e "${green}Your instance has been successfully created!${normal} (From $(IMAGE_FAMILY))"
	@echo -e "Run ${cyan}${underline}make instance.start${normal} and then ${cyan}${underline}make devstack.run${normal} to start devstack servers."
