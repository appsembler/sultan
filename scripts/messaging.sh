#!/bin/bash

current_dir="$(dirname "$0")"
configs_dir="$(dirname "$current_dir")/configs"

# Source configurations variables
source $configs_dir/.configs
for f in $configs_dir/.configs.*; do source $f; done

message() {
  #############################################################################
  # Format: message "message text" "extra info" $COLOR
  #############################################################################
  if [ -z ${2+x} ] || [ -z "$2" ]; then description="$2"; else description="[$2]"; fi

  ENDCOLS=`expr $COLS - ${#1}`
  printf '%s%s%*s%s\n' "$1" "${3:-$GRAY}" $ENDCOLS "$description" "$NORMAL"
}

dim() {
  printf "${GRAY}"
  message "$1" "$2"
}

success() {
  printf "${GREEN}"
  message "$1" "$2"
}

warn() {
  printf "${YELLOW}"
  message "$1" "$2"
}

error() {
  #############################################################################
  # Prints a message and throws an error.                                     #
  #############################################################################

  message "${RED}${BOLD}ERROR: ${NORMAL}${RED}$1${NORMAL}"
  exit 1
}


generic_error() {

printf "This might caused by one of the following reasons:\n\
	    * The instance is not set up yet. To set up an instance run make instance.setup.\n\
	    * The instance was stopped. Check the status of your instance using make instance.describe.status and start it by running make instance.start.\n\
	    * The instance might have been restricted under a previous IP of yours. To allow your current IP from accessing the instance run make instance.restrict."

	printf ''
	printf "${PURPLE}An error happened while executing the command you just used!"
	printf "While this might be an issue with the tool, we would like you to do a little bit more debugging:"
	printf "    * Run ${BOLD}${CYAN}make config.debug${NORMAL}${MAGENTA} and check if all of your environment variables hold the correct values."
	printf "    * Toggle the verbosity settings (${BOLD}VERBOSITY${NORMAL}${MAGENTA}, and ${BOLD}SHELL_OUTPUT${NORMAL}${MAGENTA}) in your env file. Follow instructions in the comments above  of them for more details."
	printf "    * Check https://github.com/appsembler/sultan/wiki for a detailed documentation on the configuration process."
	printf "\nIf you couldn't identify the cause of the problem, please submit an issue on https://github.com/appsembler/sultan/issues.${NORMAL}"
}
