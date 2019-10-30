
environment.debug:  ## Prints the values of the environemnt variables to be used in the make command as define in .env.* files.
	@echo ALLOW_FIREWALL = $(ALLOW_FIREWALL)
	@echo ANSIBLE_OUTPUT = $(ANSIBLE_OUTPUT)
	@echo DENY_FIREWALL = $(DENY_FIREWALL)
	@echo DEVSTACK_REPO_BRANCH = $(DEVSTACK_REPO_BRANCH)
	@echo DEVSTACK_REPO_URL = $(DEVSTACK_REPO_URL)
	@echo DEVSTACK_RUN_COMMAND = $(DEVSTACK_RUN_COMMAND)
	@echo DEVSTACK_WORK_DIR = $(DEVSTACK_WORK_DIR)
	@echo DISK_SIZE = $(DISK_SIZE)
	@echo HOST_NAME = $(HOST_NAME)
	@echo HOSTS_FILE = $(HOSTS_FILE)
	@echo IMAGE_FAMILY = $(IMAGE_FAMILY)
	@echo IMAGE_NAME = $(IMAGE_NAME)
	@echo INSTANCE_NAME = $(INSTANCE_NAME)
	@echo INSTANCE_TAG = $(INSTANCE_TAG)
	@echo INVENTORY = $(INVENTORY)
	@echo MACHINE_TYPE = $(MACHINE_TYPE)
	@echo MOUNT_DIR = $(MOUNT_DIR)
	@echo PROJECT_ID = $(PROJECT_ID)
	@echo RESTRICT_INSTANCE = $(RESTRICT_INSTANCE)
	@echo SERVICE_ACCOUNT_EMAIL = $(SERVICE_ACCOUNT_EMAIL)
	@echo SERVICE_KEY_PATH = $(SERVICE_KEY_PATH)
	@echo SSH_KEY = $(SSH_KEY)
	@echo TAHOE_HOST_NAME = $(TAHOE_HOST_NAME)
	@echo TMP_DIR = $(TMP_DIR)
	@echo USER_NAME = $(USER_NAME)
	@echo VERBOSITY = $(VERBOSITY)
	@echo ZONE = $(ZONE)

local.ssh.config: ve/bin/ansible-playbook
	@echo Updating ~/.ssh/config file ...
	$(eval IP_ADDRESS := $(shell make instance.ip))
	@. ve/bin/activate; ansible-playbook local.yml \
		--connection=local \
		-i '127.0.0.1,' \
		--tags ssh_config \
		-e "IP_ADDRESS=$(IP_ADDRESS) USER=$(USER_NAME) SSH_KEY=$(SSH_KEY)" > $(ANSIBLE_OUTPUT)
	@ssh-add $(SSH_KEY)

local.inventory.config: ve/bin/ansible-playbook
	@echo Updating your inventory credentials ...
	@. ve/bin/activate; ansible-playbook local.yml \
		--connection=local \
		-i '127.0.0.1,' \
		--tags inventory \
		-e "PROJECT_ID=$(PROJECT_ID) SERVICE_ACCOUNT_EMAIL=$(SERVICE_ACCOUNT_EMAIL) SERVICE_KEY_PATH=$(SERVICE_KEY_PATH)" > $(ANSIBLE_OUTPUT)
	@ssh-add $(SSH_KEY)

local.hosts.update: ve/bin/ansible-playbook  ## Updates your hosts file by adding the necessary hosts to it.
	@echo Updating /etc/hosts file ...

	$(eval IP_ADDRESS := $(shell make instance.ip))
	@. ve/bin/activate; sudo ansible-playbook --connection=local -i '127.0.0.1,' --tags hosts_update -e "IP_ADDRESS=$(IP_ADDRESS) TAHOE_HOST_NAME=$(TAHOE_HOST_NAME)" local.yml > $(ANSIBLE_OUTPUT)

local.hosts.revert: ve/bin/ansible-playbook  ## Updates your hosts file by removing the added hosts from it.
	@echo Reverting changes made on /etc/hosts file ...
	@echo Your local host sudo password might be required.
	@. ve/bin/activate; sudo ansible-playbook --connection=local -i '127.0.0.1,' --tags hosts_revert local.yml > $(ANSIBLE_OUTPUT)
