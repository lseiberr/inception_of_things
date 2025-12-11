#!/bin/bash

# basic config
dnf update -y
dnf install -y curl
dnf update -y
dnf upgrade -y
dnf install -y net-tools

sudo systemctl stop firewalld || true
sudo systemctl disable firewalld || true

# récupérer l'IP du serveur depuis un fichier partagé
if [ ! -f /vagrant_shared/server-ip ]; then
  echo "Server IP file /vagrant_shared/server-ip not found."
  exit 1
fi
SERVER_IP=$(cat /vagrant_shared/server-ip | tr -d '\n')

# checking token
TIMEOUT=10
while [ ! -f "/vagrant_shared/token" ]; do
    echo "[WAIT] - En attente de /vagrant_shared/token (reste ${TIMEOUT}s)"
    ls -l /vagrant_shared || true
    sleep 2
    TIMEOUT=$((TIMEOUT - 2))
    if [ "$TIMEOUT" -le 0 ]; then
        echo "[ERROR] - Token file not found after timeout."
        exit 1
    fi
done

# k3s
echo "[LOG] - Install k3s"
echo "[LOG] - Master node: ${SERVER_IP}"
export K3S_TOKEN_FILE=/vagrant_shared/token
export K3S_URL=https://${SERVER_IP}:6443

curl -sfL https://get.k3s.io | sh -
if [ $? -ne 0 ]; then
    echo "Failed to install k3s. Exiting."
    exit 1
fi

echo 'export PATH="/sbin:$PATH"' >> "$HOME/.bashrc"
echo "alias k='kubectl'" | sudo tee /etc/profile.d/00-aliases.sh > /dev/null
