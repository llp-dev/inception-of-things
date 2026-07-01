#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFS_DIR="${SCRIPT_DIR}/../confs"

BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"
export PATH="${BIN_DIR}:${PATH}"

# Start Podman socket and expose it as a Docker-compatible endpoint for k3d.
systemctl --user start podman.socket
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/podman/podman.sock"
# Tell k3d to mount the Podman socket inside containers instead of /var/run/docker.sock.
export DOCKER_SOCK="${XDG_RUNTIME_DIR}/podman/podman.sock"

until docker info >/dev/null 2>&1; do
  echo "Waiting for Podman socket..." >&2
  sleep 2
done

# Install kubectl if missing.
if ! command -v kubectl >/dev/null 2>&1; then
  curl -sLo "${BIN_DIR}/kubectl" \
    "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x "${BIN_DIR}/kubectl"
fi

# Install k3d if missing.
if ! command -v k3d >/dev/null 2>&1; then
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh \
    | USE_SUDO=false K3D_INSTALL_DIR="${BIN_DIR}" sh
fi

# Create cluster.
k3d cluster create inception --wait

mkdir -p ~/.kube
k3d kubeconfig get inception > ~/.kube/config
export KUBECONFIG=~/.kube/config

# Namespaces.
kubectl create namespace argocd
kubectl create namespace dev

# Install Argo CD.
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Apply Argo CD Application (points Argo CD at the lepereir repo).
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
