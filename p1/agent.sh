#!/bin/bash
set -euxo pipefail

# Mise à jour des paquets
sudo apt-get update -y
sudo apt-get upgrade -y

# Installation de K3s en mode Agent
K3S_URL=https://192.168.56.110:6443
K3S_TOKEN="$1"  # le token passé par Vagrant
curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -

# kubectl est aussi dispo ici en tant que client (via k3s)
