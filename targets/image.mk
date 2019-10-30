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

instance.image.master.create: instance.stop instance.image.master.delete  ## Creates a master image from your instance on GCP.
	@echo Create a new master devstack image on GCP...
	@make NAME=$(IMAGE_FAMILY) instance.image.create.command
