#!/bin/bash
set -euxo pipefail

# Mise à jour des paquets
sudo apt-get update -y
sudo apt-get upgrade -y

# Installation de K3s en mode Server
curl -sfL https://get.k3s.io | sh -

# K3s installe déjà kubectl (linké sur k3s kubectl) et un kubeconfig
# On copie juste le kubeconfig dans /vagrant pour l'hôte et on sécurise le token.

# KUBECONFIG pour la VM et le host (facultatif mais pratique)
sudo mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

# Copie aussi vers /vagrant pour que tu puisses l'utiliser depuis ton Mac
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/kubeconfig.yaml
sudo chown vagrant:vagrant /vagrant/kubeconfig.yaml

# Rien d'autre à installer : kubectl est déjà fourni par K3s
