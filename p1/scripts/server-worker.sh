#!/bin/sh
set -e

# Prerequisites and the kubectl alias are installed by scripts/common.sh.

until curl -sfk https://192.168.56.110:6443/ping >/dev/null 2>&1; do
  sleep 5
done

curl -sfL https://get.k3s.io | \
  K3S_URL="https://192.168.56.110:6443" \
  K3S_TOKEN="inception42" \
  INSTALL_K3S_EXEC="agent --flannel-iface eth1 --node-ip 192.168.56.111" \
  sh -
