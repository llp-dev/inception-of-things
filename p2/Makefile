# p2 - IoT: single-node K3s with 3 web apps behind a Traefik ingress
#
# The home partition (~/) is only ~4.7G, too small for the VM. This Makefile
# redirects all Vagrant/VirtualBox storage to /goinfre (large, local disk).
# The redirection is scoped to `make` only: nothing is written to your shell
# rc files, and VAGRANT_HOME is exported just for these recipes.

USER    := $(shell whoami)
GOINFRE := /goinfre/$(USER)

# Vagrant boxes + metadata live here instead of ~/.vagrant.d (exported to recipes).
export VAGRANT_HOME := $(GOINFRE)/.vagrant.d

# VirtualBox VM disks live here instead of ~/VirtualBox VMs.
VBOX_DIR := $(GOINFRE)/VirtualBox

SERVER := $(USER)S

.PHONY: up validate halt status ssh-server destroy clean re

# Check that the Vagrantfile is syntactically valid.
validate:
	vagrant validate

# Prepare storage on /goinfre, then bring the VM up.
up:
	@mkdir -p "$(VAGRANT_HOME)" "$(VBOX_DIR)"
	@VBoxManage setproperty machinefolder "$(VBOX_DIR)"
	vagrant up

halt:
	vagrant halt

status:
	vagrant status

ssh-server:
	vagrant ssh $(SERVER)

# Delete the VM and its disk.
destroy:
	vagrant destroy -f

# destroy + wipe local .vagrant state.
clean: destroy
	rm -rf .vagrant

# Full rebuild.
re: clean up
