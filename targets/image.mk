image.delete.command:
	@echo Removing $(NAME) image from GCP...
	@(gcloud compute images delete $(NAME) \
		--project=$(PROJECT_ID) \
		--verbosity $(VERBOSITY) \
		--quiet && \
	echo -e "${green}Image deleted successfully!${normal}") || echo -e "${yellow}Couldn't find the image on GCP.    (SKIPPING)"

image.delete:   ## Deletes your image from GCP.
	@make NAME=$(IMAGE_NAME) image.delete.command

image.master.delete:
	@make NAME=$(IMAGE_FAMILY) image.delete.command

image.create.command:
	@(gcloud beta compute images create $(NAME) \
		--source-disk=$(INSTANCE_NAME) \
		--source-disk-zone=$(ZONE) \
		--family=$(IMAGE_FAMILY) \
		--labels=user=$(INSTANCE_NAME) \
		--project=$(PROJECT_ID) \
		--verbosity $(VERBOSITY) \
		--quiet && \
	echo -e "${green}Image created successfully!${normal}") || echo -e "${yellow}Couldn't find the image on GCP.    (SKIPPING)${normal}"

image.master.create: instance.stop image.master.delete  ## Creates a master image from your instance on GCP.
	@echo -e "Creating a new master devstack image on GCP...    ${dim}($(IMAGE_FAMILY))${normal}"
	@make NAME=$(IMAGE_FAMILY) image.create.command
