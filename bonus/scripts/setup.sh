#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFS_DIR="${SCRIPT_DIR}/../confs"

GITLAB_ROOT_PASSWORD="Inception42!"

# Install tools
apk add --no-cache docker docker-cli curl git
rc-update add docker boot
rc-service docker start

until docker info >/dev/null 2>&1; do sleep 2; done

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && mv kubectl /usr/local/bin/

# k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | sh

# Create cluster
k3d cluster create inception --wait

mkdir -p ~/.kube
k3d kubeconfig get inception > ~/.kube/config
export KUBECONFIG=~/.kube/config

# Namespaces
kubectl create namespace argocd
kubectl create namespace dev
kubectl create namespace gitlab

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy GitLab CE (Omnibus single container)
kubectl apply -n gitlab -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitlab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitlab
  template:
    metadata:
      labels:
        app: gitlab
    spec:
      containers:
      - name: gitlab
        image: gitlab/gitlab-ce:latest
        ports:
        - containerPort: 80
        - containerPort: 22
        env:
        - name: GITLAB_OMNIBUS_CONFIG
          value: |
            external_url 'http://gitlab.local'
            gitlab_rails['initial_root_password'] = '${GITLAB_ROOT_PASSWORD}'
---
apiVersion: v1
kind: Service
metadata:
  name: gitlab-svc
spec:
  selector:
    app: gitlab
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: ssh
    port: 22
    targetPort: 22
EOF

# Wait for Argo CD and GitLab in parallel
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=600s deployment/gitlab -n gitlab

# Create API token via Rails runner
GITLAB_TOKEN=$(kubectl exec -n gitlab deployment/gitlab -- \
  gitlab-rails runner \
  "token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api, :read_repository, :write_repository], name: 'setup', expires_at: 1.year.from_now); puts token.token" \
  2>/dev/null)

# Port-forward GitLab to push manifests
kubectl port-forward svc/gitlab-svc -n gitlab 8929:80 &
PF_PID=$!
until curl -sf http://localhost:8929/api/v4/version >/dev/null 2>&1; do sleep 5; done

# Create project
curl -sf -X POST http://localhost:8929/api/v4/projects \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  --data "name=inception&visibility=public&initialize_with_readme=true"

sleep 5

# Push app manifests
TMPDIR=$(mktemp -d)
git clone "http://root:${GITLAB_ROOT_PASSWORD}@localhost:8929/root/inception.git" "${TMPDIR}/inception"
mkdir -p "${TMPDIR}/inception/app"
cp "${CONFS_DIR}/app/deployment.yaml" "${TMPDIR}/inception/app/"
cd "${TMPDIR}/inception"
git config user.email "lepereir@student.42.fr"
git config user.name "lepereir"
git add . && git commit -m "initial deployment" && git push

kill ${PF_PID} 2>/dev/null || true

# Register GitLab repo in Argo CD
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: http://gitlab-svc.gitlab.svc.cluster.local/root/inception
  username: root
  password: "${GITLAB_ROOT_PASSWORD}"
EOF

kubectl apply -f "${CONFS_DIR}/application.yaml"

echo ""
echo "Argo CD password: $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)"
echo "Access Argo CD:  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Access GitLab:   kubectl port-forward svc/gitlab-svc -n gitlab 8929:80"
echo "Access app:      kubectl port-forward svc/wil-playground-svc -n dev 8888:8888"
