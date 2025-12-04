#!/bin/bash

# Mise à jour des paquets
sudo apt-get update -y
sudo apt-get upgrade -y

# Installation de K3s en mode Server
curl -sfL https://get.k3s.io | sh -

# Installation de kubectl
sudo apt-get install -y kubectl
