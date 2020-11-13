#!/bin/bash

autoload bashcompinit
bashcompinit


current_dir="$(dirname "$0")"
completion_dir="$current_dir"/sultan-completion.bash

# shellcheck disable=SC1090
source "$completion_dir"
