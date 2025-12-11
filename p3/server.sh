#!/bin/bash
set -e

# --------------------------------------------------
# 1. Mise à jour et outils de base
# --------------------------------------------------
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  git \
  bash-completion \
  lsof

# --------------------------------------------------
# 2. Installation de Docker
# --------------------------------------------------
sudo mkdir -p /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# mettre vagrant dans le groupe docker
sudo usermod -aG docker vagrant || true
sudo systemctl enable docker
sudo systemctl restart docker

# --------------------------------------------------
# 3. Installation de kubectl
# --------------------------------------------------
if ! command -v kubectl >/dev/null 2>&1; then
  ARCH=$(dpkg --print-architecture) # amd64 / arm64
  KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
fi

# complétion + alias
echo 'alias k="kubectl"' >> /home/vagrant/.bashrc
echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
echo 'complete -o default -F __start_kubectl k' >> /home/vagrant/.bashrc

# --------------------------------------------------
# 4. Installation de k3d
# --------------------------------------------------
if ! command -v k3d >/dev/null 2>&1; then
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# --------------------------------------------------
# 5. Création du cluster k3d (avec Traefik)
# --------------------------------------------------
CLUSTER_NAME="lseiberrs-cluster"

# si cluster déjà là, le supprimer pour repartir propre en reprovision
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
  k3d cluster delete "$CLUSTER_NAME"
fi

k3d cluster create "$CLUSTER_NAME" \
  --servers 1 \
  --agents 1 \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer"

# kubeconfig
export KUBECONFIG=$(k3d kubeconfig write "$CLUSTER_NAME")
kubectl config use-context "k3d-${CLUSTER_NAME}"

# rendre KUBECONFIG persistant pour l'utilisateur vagrant
echo "export KUBECONFIG=\$(k3d kubeconfig write \"$CLUSTER_NAME\")" >> /home/vagrant/.bashrc
echo "kubectl config use-context k3d-${CLUSTER_NAME}" >> /home/vagrant/.bashrc
chown vagrant:vagrant /home/vagrant/.bashrc

# vérifier cluster
kubectl get nodes

# --------------------------------------------------
# 6. Namespaces + Argo CD
# --------------------------------------------------
kubectl create namespace dev    || true
kubectl create namespace argocd || true

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait --for=condition=Available deployment/argocd-server \
  -n argocd --timeout=300s

echo "ArgoCD installed"

# --------------------------------------------------
# 6-bis. Forcer Argo CD en mode HTTP (--insecure)
# --------------------------------------------------
# On ajoute l'argument --insecure au container argocd-server pour éviter les redirections HTTPS
kubectl -n argocd patch deploy argocd-server \
  --type='json' \
  -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/args",
      "value": ["/usr/local/bin/argocd-server", "--staticassets", "/shared/app", "--insecure"]
    }
  ]'

# Attendre que le rollout soit terminé
kubectl -n argocd rollout status deploy/argocd-server --timeout=120s

# --------------------------------------------------
# 7. Application Argo CD + ingress
# --------------------------------------------------
kubectl apply -n argocd -f /vagrant/argocd-wil42-app.yaml
echo "[+] Ressources dans le namespace dev :"
kubectl -n dev get all || true

kubectl apply -f /vagrant/ingress-argocd.yaml
kubectl get ingress -n argocd

#voir le mot de passe initial
#kubectl -n argocd get secret argocd-initial-admin-secret \
#  -o jsonpath="{.data.password}" | base64 -d && echo

#voir le changement d'image dans le déploiement
#kubectl -n dev describe deploy wil-playground | grep Image

#comment curl de la vm
#kubectl -n dev port-forward svc/wil-playground 9090:80
#curl -v http://127.0.0.1:9090/
