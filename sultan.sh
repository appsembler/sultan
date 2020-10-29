#!/bin/sh

# Includes
current_dir="$(dirname "$0")"
source "$current_dir/scripts/messaging.sh"

# Source configurations variables
source configs/.configs
for f in configs/.configs.*; do source $f; done


instance() {
	./scripts/instance.sh $@
}

devstack() {
	./scripts/devstack.sh $@
}

workflow() {
	./scripts/workflow.sh $@
}

image() {
	./scripts/image.sh $@
}

firewall() {
	./scripts/firewall.sh $@
}

local() {
	./scripts/local.sh $@
}

configs() {
	./scripts/configurations.sh $@
}

"$@"
