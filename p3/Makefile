# p3 - IoT: k3s-in-Podman cluster with Argo CD GitOps (k3d)
#
# Runs entirely on the local machine via Podman + k3d.
# No Vagrant or VirtualBox involved — no storage redirect needed.

CLUSTER := inception

export DOCKER_HOST := unix://$(XDG_RUNTIME_DIR)/podman/podman.sock
export DOCKER_SOCK := $(XDG_RUNTIME_DIR)/podman/podman.sock

.PHONY: up halt status password destroy clean re

# Create the k3d cluster and deploy Argo CD + the app.
up:
	sh scripts/setup.sh

# Stop the k3d cluster (keeps cluster state).
halt:
	k3d cluster stop $(CLUSTER)

# Show cluster status.
status:
	k3d cluster list

# Print the Argo CD admin password.
password:
	@kubectl get secret argocd-initial-admin-secret -n argocd \
	  -o jsonpath="{.data.password}" | base64 -d
	@echo ""

# Delete the k3d cluster.
destroy:
	k3d cluster delete $(CLUSTER)

# destroy + wipe local state (no .vagrant equivalent in p3).
clean: destroy

# Full rebuild.
re: clean up
