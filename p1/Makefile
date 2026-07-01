# p1 - IoT: K3s cluster on two Alpine VMs (Vagrant + VirtualBox)
#
# The home partition (~/) is only ~4.7G, too small for two VMs. This Makefile
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
WORKER := $(USER)SW

.PHONY: up validate halt status ssh-server ssh-worker destroy clean re

# Check that the Vagrantfile is syntactically valid.
validate:
	vagrant validate

# Prepare storage on /goinfre, then bring both VMs up.
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

ssh-worker:
	vagrant ssh $(WORKER)

# Delete the VMs and their disks.
destroy:
	vagrant destroy -f

# destroy + wipe local .vagrant state.
clean: destroy
	rm -rf .vagrant

# Full rebuild.
re: clean up
