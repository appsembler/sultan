workflow.suspend: devstack.unmount image.master.create instance.stop
	@echo -e "${yellow}Making a new master image and stopping the instance${normal}"

workflow.resume: instance.setup.image.master devstack.run devstack.mount
	@echo -e "${green}Recreating instance from the master image and starting it up!${normal}"
