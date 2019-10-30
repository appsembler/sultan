instance.firewall.deny.delete:   ## Deletes the GCP Firewall's rule that prevents accessing your instance by all ways.
	@echo Removing DENY firewall rule from gcp...
	@gcloud compute firewall-rules delete $(DENY_FIREWALL) \
		--project=$(PROJECT_ID) \
		--verbosity $(VERBOSITY) \
		--quiet \
		|| echo 'No previous deny firewall found'

instance.firewall.deny.create:  ## Creates a GCP Firewall's rule to prevent all kind of access to your instance.
ifeq ($(RESTRICT_INSTANCE),true)
	@echo Creating DENY firewall rule in gcp...
	@gcloud compute firewall-rules create $(DENY_FIREWALL) \
		--action=deny \
		--direction=ingress \
		--rules=tcp \
		--source-ranges=0.0.0.0/0 \
		--priority=1000 \
		--target-tags=$(INSTANCE_TAG) \
		--project=$(PROJECT_ID)
else
	@echo 'Skipping as your settings advise not to restricted your instance.'
endif

instance.firewall.allow.delete:  ## Deletes the GCP Firewall's rule that allows your IP to access your instance.
	@echo Removing ALLOW firewall rule from gcp...
	@gcloud compute firewall-rules delete $(ALLOW_FIREWALL) \
		--project=$(PROJECT_ID) \
		--verbosity $(VERBOSITY) \
		--quiet \
		|| echo 'No previous allow firewall found'

instance.firewall.allow.create:  ## Creates a GCP Firewall's rule allowing your IP to access your instance.
ifeq ($(RESTRICT_INSTANCE),true)
	$(eval MY_PUBLIC_IP := $(shell curl ifconfig.me))
else
	$(eval MY_PUBLIC_IP := 0.0.0.0/0)
endif

	@echo Creating ALLOW firewall rule in gcp...
	gcloud compute firewall-rules create $(ALLOW_FIREWALL) \
		--action allow \
		--direction ingress \
		--rules tcp \
		--source-ranges $(MY_PUBLIC_IP) \
		--priority 50 \
		--target-tags=$(INSTANCE_TAG)\
		--project=$(PROJECT_ID)

instance.firewall.deny.refresh: instance.firewall.deny.delete instance.firewall.deny.create  ## Refreshes the deny rule on GCP Firewall by deleting the old rule and creating a new one.
ifeq ($(RESTRICT_INSTANCE),true)
	@echo "Deny rule has been updated on the firewall."
else
	@echo 'Skipping as your settings advise not to restricted your instance.'
endif

instance.firewall.allow.refresh: instance.firewall.allow.delete instance.firewall.allow.create  ## Refreshes the allow rule on GCP Firewall by deleting the old rule and creating a new one.
ifeq ($(RESTRICT_INSTANCE),true)
	@echo "Allow rule has been updated on the firewall."
else
	@echo 'Skipping as your settings advise not to restricted your instance.'
endif
