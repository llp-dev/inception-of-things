#!/bin/sh
set -e

# Prerequisites and the kubectl alias are installed by scripts/common.sh.

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --flannel-iface eth1 --node-ip 192.168.56.110" \
  sh -

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
  sleep 2
done

# Deploy the three apps and the ingress (confs synced to /vagrant_shared).
kubectl apply -f /vagrant_shared/
