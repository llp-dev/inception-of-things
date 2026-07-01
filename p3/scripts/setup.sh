#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFS_DIR="${SCRIPT_DIR}/../confs"

# Install Docker
apk add --no-cache docker docker-cli
rc-update add docker boot
rc-service docker start

until docker info >/dev/null 2>&1; do
  sleep 2
done

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | sh

# Create cluster
k3d cluster create inception --wait

mkdir -p ~/.kube
k3d kubeconfig get inception > ~/.kube/config
export KUBECONFIG=~/.kube/config

# Namespaces
kubectl create namespace argocd
kubectl create namespace dev

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Apply Argo CD Application
kubectl apply -f "${CONFS_DIR}/application.yaml"

echo ""
echo "Argo CD admin password:"
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
echo ""
echo "Run to access Argo CD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Run to access the app:"
echo "  kubectl port-forward svc/wil-playground-svc -n dev 8888:8888"
