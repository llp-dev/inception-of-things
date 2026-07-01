#!/bin/sh
set -e

# Prerequisites and the kubectl alias are installed by scripts/common.sh.

curl -sfL https://get.k3s.io | \
  K3S_TOKEN="inception42" \
  INSTALL_K3S_EXEC="server --flannel-iface eth1 --node-ip 192.168.56.110" \
  sh -

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
  sleep 2
done

mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
chmod 600 /home/vagrant/.kube/config
