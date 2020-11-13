#!/bin/bash

current_dir="$(dirname "$0")"
configs_dir="$(dirname "$current_dir")/configs"

# Source configurations variables
for f in "$configs_dir"/.configs* ; do
    # shellcheck disable=SC1090
    source "$f"
done

message() {
  #############################################################################
  # Usage:
  #   message "message body" "extra info" $COLOR
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

  if [ -n "$2" ]; then
    printf "\n%s\n" "$2"
  else
    # shellcheck disable=SC2059
    printf "${PURPLE}An error occurred while executing the command you just used!${NORMAL}${MAGENTA}
While this might be an issue with the tool, we would like you to do a little bit more debugging:
  * Run ${BOLD}${CYAN}sultan config debug${NORMAL}${MAGENTA} and check if all of your environment variables hold the correct values.
  * Toggle the debug setting (${BOLD}DEBUG${NORMAL}${MAGENTA} in your env file. Follow instructions in the comments above for more details.
  * Check https://github.com/appsembler/sultan/wiki for a detailed documentation on the configuration process.

If you couldn't identify the cause of the problem, please submit an issue on https://github.com/appsembler/sultan/issues.${NORMAL}\n"
  fi

  exit 1
}
