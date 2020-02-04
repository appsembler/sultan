
environment.debug:  ## Prints the values of the environemnt variables to be used in the make command as define in .configs.* files.
	@echo -e "${cyan}ALLOW_FIREWALL${normal}        $(ALLOW_FIREWALL)"
	@echo -e "${cyan}DENY_FIREWALL${normal}         $(DENY_FIREWALL)"
	@echo -e "${cyan}DEVSTACK_REPO_BRANCH${normal}  $(DEVSTACK_REPO_BRANCH)"
	@echo -e "${cyan}DEVSTACK_REPO_URL${normal}     $(DEVSTACK_REPO_URL)"
	@echo -e "${cyan}DEVSTACK_RUN_COMMAND${normal}  $(DEVSTACK_RUN_COMMAND)"
	@echo -e "${cyan}DEVSTACK_WORK_DIR${normal}     $(DEVSTACK_WORK_DIR)"
	@echo -e "${cyan}DISK_SIZE${normal}             $(DISK_SIZE)"
	@echo -e "${cyan}EDX_HOST_NAMES${normal}        $(EDX_HOST_NAMES)"
	@echo -e "${cyan}HOST_NAME${normal}             $(HOST_NAME)"
	@echo -e "${cyan}HOSTS_FILE${normal}            $(HOSTS_FILE)"
	@echo -e "${cyan}IMAGE_FAMILY${normal}          $(IMAGE_FAMILY)"
	@echo -e "${cyan}IMAGE_NAME${normal}            $(IMAGE_NAME)"
	@echo -e "${cyan}INSTANCE_EXTRA_ARGS${normal}   $(INSTANCE_EXTRA_ARGS)"
	@echo -e "${cyan}INSTANCE_NAME${normal}         $(INSTANCE_NAME)"
	@echo -e "${cyan}INSTANCE_TAG${normal}          $(INSTANCE_TAG)"
	@echo -e "${cyan}INVENTORY${normal}             $(INVENTORY)"
	@echo -e "${cyan}MACHINE_TYPE${normal}          $(MACHINE_TYPE)"
	@echo -e "${cyan}MOUNT_DIR${normal}             $(MOUNT_DIR)"
	@echo -e "${cyan}OPENEDX_RELEASE${normal}       $(OPENEDX_RELEASE)"
	@echo -e "${cyan}PROJECT_ID${normal}            $(PROJECT_ID)"
	@echo -e "${cyan}RESTRICT_INSTANCE${normal}     $(RESTRICT_INSTANCE)"
	@echo -e "${cyan}SERVICE_ACCOUNT_EMAIL${normal} $(SERVICE_ACCOUNT_EMAIL)"
	@echo -e "${cyan}SERVICE_KEY_PATH${normal}      $(SERVICE_KEY_PATH)"
	@echo -e "${cyan}SHELL_OUTPUT${normal}          $(SHELL_OUTPUT)"
	@echo -e "${cyan}SSH_KEY${normal}               $(SSH_KEY)"
	@echo -e "${cyan}TMP_DIR${normal}               $(TMP_DIR)"
	@echo -e "${cyan}USER_NAME${normal}             $(USER_NAME)"
	@echo -e "${cyan}VERBOSITY${normal}             $(VERBOSITY)"
	@echo -e "${cyan}ZONE${normal}                  $(ZONE)"

local.ssh.config: ve/bin/ansible-playbook
	@echo -e "Updating necessary records in SSH related files...    ${dim}[~/.ssh/config, ~/.ssh/knwon_hosts]${normal}"
	$(eval IP_ADDRESS := $(shell make instance.ip))
	@. ve/bin/activate; ansible-playbook local.yml \
		--connection=local \
		-i '127.0.0.1,' \
		--tags ssh_config \
		-e "IP_ADDRESS=$(IP_ADDRESS) USER=$(USER_NAME) SSH_KEY=$(SSH_KEY)" > $(SHELL_OUTPUT) || (echo -e "${redbold}ERROR configuring SSH connection in your machine.${normal}" && make error && exit 1)
	@ssh-add $(SSH_KEY)
	@echo -e "${green}SSH connection between your machine and the instnace has been configured successfully!${normal}"

local.inventory.config: ve/bin/ansible-playbook
	@echo -e "Updating your inventory credentials...    ${dim}(dynamic-inventory/gce.ini)${normal}"
	@. ve/bin/activate; ansible-playbook local.yml \
		--connection=local \
		-i '127.0.0.1,' \
		--tags inventory \
		-e "PROJECT_ID=$(PROJECT_ID) SERVICE_ACCOUNT_EMAIL=$(SERVICE_ACCOUNT_EMAIL) SERVICE_KEY_PATH=$(SERVICE_KEY_PATH)" > $(SHELL_OUTPUT) || (echo -e "${redbold}ERROR configuring your inventory.${normal}" && make error && exit 1)
	@ssh-add $(SSH_KEY)
	@echo -e "${green}Your inventory has been configured successfully!${normal}"

local.hosts.update: ve/bin/ansible-playbook  ## Updates your hosts file by adding the necessary hosts to it.
	@echo -e "Updating your hosts records...    ${dim}(/etc/hosts)${normal}"

	$(eval IP_ADDRESS := $(shell make instance.ip))
	@make sudocheck
	@. ve/bin/activate; sudo ansible-playbook \
		--connection=local \
		-i '127.0.0.1,' \
		--tags hosts_update \
		-e "IP_ADDRESS=$(IP_ADDRESS) EDX_HOST_NAMES=$(EDX_HOST_NAMES)" local.yml > $(SHELL_OUTPUT) || (echo -e "${redbold}ERROR configuring hosts records.${normal}" && make error && exit 1)
	@echo -e "${green}Your hosts have been configured successfully!${normal}"

local.hosts.revert: ve/bin/ansible-playbook  ## Updates your hosts file by removing the added hosts from it.
	@echo -e "Reverting made local changes...    ${dim}[/etc/hosts, ~/.ssh/config]${normal}"
	@make sudocheck
	@. ve/bin/activate; sudo ansible-playbook \
		--connection=local \
		-i '127.0.0.1,' \
		-e "EDX_HOST_NAMES=$(EDX_HOST_NAMES)" \
		--tags hosts_revert local.yml > $(SHELL_OUTPUT) || (echo -e "${redbold}ERROR reverting local changes.${normal}" && make error && exit 1)
	@echo -e "${green}Your local changes have been reverted successfully!${normal}"

CXXARCH:=$(shell $(CXX) -dumpmachine | grep -i 'x86_64')

sudocheck:
	@if ! sudo -n true 2>/dev/null ; then \
		echo -e "${yellow}Please enter your sudo password...${normal}"; \
	fi
