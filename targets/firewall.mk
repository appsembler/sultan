instance.firewall.deny.delete:   ## Deletes the GCP Firewall's rule that prevents accessing your instance by all ways.
	@echo -e "Removing DENY firewall rule from gcp...    ${dim}($(DENY_FIREWALL))${normal}"
	@(gcloud compute firewall-rules delete $(DENY_FIREWALL) \
		--project=$(PROJECT_ID) \
		--verbosity $(VERBOSITY) \
		--quiet && echo -e "\n${green}DENY firewall has been successfully deleted!${normal}") || echo -e "${yellow}No previous deny firewall found. (SKIPPING)${normal}"

instance.firewall.deny.create:  ## Creates a GCP Firewall's rule to prevent all kind of access to your instance.
ifeq ($(RESTRICT_INSTANCE),true)
	@echo -e "Creating DENY firewall rule in gcp...    ${dim}($(DENY_FIREWALL))${normal}"
	@(gcloud compute firewall-rules create $(DENY_FIREWALL) \
		--quiet \
		--verbosity $(VERBOSITY) \
		--action=deny \
		--direction=ingress \
		--rules=tcp \
		--source-ranges=0.0.0.0/0 \
		--priority=1000 \
		--target-tags=$(INSTANCE_TAG) \
		--project=$(PROJECT_ID) && echo -e "\n${green}DENY firewall has been successfully created!${normal}") || echo -e "${yellow}Firewall already exists. (SKIPPING)${normal}"
endif

instance.firewall.allow.delete:  ## Deletes the GCP Firewall's rule that allows your IP to access your instance.
	@echo -e "Removing ALLOW firewall rule from gcp...    ${dim}($(ALLOW_FIREWALL))${normal}"
	@gcloud compute firewall-rules delete $(ALLOW_FIREWALL) \
		--project=$(PROJECT_ID) \
		--verbosity $(VERBOSITY) \
		--quiet \
		|| echo -e "${yellow}No previous allow firewall found. (SKIPPING)${normal}"

instance.firewall.allow.create:  ## Creates a GCP Firewall's rule allowing your IP to access your instance.
ifeq ($(RESTRICT_INSTANCE),true)
	$(eval MY_PUBLIC_IP := $(shell curl ifconfig.me))
else
	$(eval MY_PUBLIC_IP := 0.0.0.0/0)
endif

	@echo -e "Creating ALLOW firewall rule in gcp...    ${dim}($(ALLOW_FIREWALL):$(MY_PUBLIC_IP))${normal}"
	@(gcloud compute firewall-rules create $(ALLOW_FIREWALL) \
		--quiet \
		--verbosity $(VERBOSITY) \
		--action allow \
		--direction ingress \
		--rules tcp \
		--source-ranges $(MY_PUBLIC_IP) \
		--priority 50 \
		--target-tags=$(INSTANCE_TAG)\
		--project=$(PROJECT_ID) && echo -e "\n${green}ALLOW firewall has been successfully created!${normal}") || echo -e "${yellow}Firewall already exists. (SKIPPING)${normal}"

instance.firewall.deny.refresh: instance.firewall.deny.delete instance.firewall.deny.create  ## Refreshes the deny rule on GCP Firewall by deleting the old rule and creating a new one.
ifeq ($(RESTRICT_INSTANCE),true)
	@echo -e "${green}Deny rule has been updated on the firewall.${normal}"
endif

instance.firewall.allow.refresh: instance.firewall.allow.delete instance.firewall.allow.create  ## Refreshes the allow rule on GCP Firewall by deleting the old rule and creating a new one.
ifeq ($(RESTRICT_INSTANCE),true)
	@echo -e "${green}Allow rule has been updated on the firewall.${normal}"
endif
