image.delete.command:
	@echo Removing $(NAME) image from GCP...
	@(gcloud compute images delete $(NAME) \
		--project=$(PROJECT_ID) \
		--verbosity $(VERBOSITY) \
		--quiet && \
	echo -e "${green}Image deleted successfully!${normal}") || echo -e "${yellow}Couldn't find the image on GCP.    (SKIPPING)"

image.delete:   ### Deletes your image from GCP.
	$(eval NAME ?= $(IMAGE_NAME))
	@echo -e "Deleting devstack image from GCP...    ${dim}($(NAME))${normal}"
	@make NAME=$(NAME) image.delete.command
	@echo -e "${green}Your image has been deleted successfully${normal}"

image.create.command:
	@(gcloud beta compute images create $(NAME) \
		--source-disk=$(INSTANCE_NAME) \
		--source-disk-zone=$(ZONE) \
		--family=$(IMAGE_FAMILY) \
		--labels=user=$(INSTANCE_NAME) \
		--project=$(PROJECT_ID) \
		--verbosity $(VERBOSITY) \
		--quiet && \
	echo -e "${green}Your image ($(NAME)) has been created successfully!${normal}") || echo -e "${yellow}Couldn't find the image on GCP.    (SKIPPING)${normal}"

image.create: instance.stop   ### Creates an image from your instance on GCP.
	$(eval NAME ?= $(IMAGE_NAME))
	@echo -e "Creating a new image from your devstack GCP instance...    ${dim}($(NAME))${normal}"
	@echo -e "${dim}This will remove any previous image with the same name. Press CTRL+C to abort...${normal}"
	@sleep 10

	@make NAME=$(NAME) image.delete.command
	@echo -e "Image is being created...    ${dim}($(NAME))${normal}"
	@make NAME=$(NAME) image.create.command
