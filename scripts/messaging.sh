#!/bin/bash

current_dir="$(dirname "$0")"
configs_dir="$(dirname "$current_dir")/configs"

# Source configurations variables
# shellcheck disable=SC1090
source "$configs_dir"/.configs
# shellcheck disable=SC1090
for f in "$configs_dir"/.configs.*; do source "$f"; done

message() {
  #############################################################################
  # Format: message "message text" "extra info" $COLOR
  #############################################################################
  if [ -z ${2+x} ] || [ -z "$2" ]; then description="$2"; else description="[$2]"; fi

  ENDCOLS=$((COLS - ${#1}))
  printf '%s%s%*s%s\n' "$1" "${3:-$GRAY}" $ENDCOLS "$description" "$NORMAL"
}

dim() {
  printf "%s" "${GRAY}"
  message "$1" "$2"
}

success() {
  printf "%s" "${GREEN}"
  message "$1" "$2"
}

warn() {
  printf "%s" "${YELLOW}"
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
	printf "%sAn error happened while executing the command you just used!" "${PURPLE}"
	printf "While this might be an issue with the tool, we would like you to do a little bit more debugging:"
	printf "    * Run %smake config.debug%s and check if all of your environment variables hold the correct values." "${BOLD}${CYAN}" "${NORMAL}${MAGENTA}"
	printf "    * Toggle the verbosity settings (%sVERBOSITY%s, and %sSHELL_OUTPUT%s) in your env file. Follow instructions in the comments above  of them for more details." "${BOLD}" "${NORMAL}${MAGENTA}" "${BOLD}" "${NORMAL}${MAGENTA}"
	printf "    * Check https://github.com/appsembler/sultan/wiki for a detailed documentation on the configuration process."
	printf "\nIf you couldn't identify the cause of the problem, please submit an issue on https://github.com/appsembler/sultan/issues.%s" "${NORMAL}"
}
