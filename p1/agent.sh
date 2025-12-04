#!/bin/bash
set -euxo pipefail

# Mise à jour des paquets
sudo apt-get update -y
sudo apt-get upgrade -y

# Installation de K3s en mode Agent
K3S_URL=https://192.168.56.110:6443
K3S_TOKEN="$1"  # le token sera passé en argument par Vagrant
curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -

# Installation de kubectl (via dépôt officiel Kubernetes)
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubectl
