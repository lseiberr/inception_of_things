#!/bin/bash

# récupérer l'IP principale non-loopback
IP="192.168.56.110"

# basic config
dnf update -y
dnf install -y curl
dnf install -y net-tools

sudo systemctl stop firewalld || true
sudo systemctl disable firewalld || true


echo "[LOG] - Server IP detected: ${IP}"
echo "${IP}" > /vagrant_shared/server-ip

# k3s
echo "[LOG] - Install k3s"
export K3S_KUBECONFIG_MODE="644"
export INSTALL_K3S_EXEC="server --node-external-ip=${IP}"

curl -sfL https://get.k3s.io | sh -
if [ $? -ne 0 ]; then
    echo "Failed to install k3s. Exiting."
    exit 1
fi

# share token
echo "[LOG] - Share token"
TIMEOUT=120
TOKEN_PATH="/var/lib/rancher/k3s/server/node-token"

while ! sudo test -f "$TOKEN_PATH"; do
    echo "[DEBUG] - En attente du token K3s à $TOKEN_PATH (TIMEOUT restant: $TIMEOUT s)"
    sleep 2
    TIMEOUT=$((TIMEOUT - 2))
    if [ "$TIMEOUT" -le 0 ]; then
        echo "[ERROR] - Token file not generated after timeout."
        sudo systemctl status k3s || true
        sudo journalctl -u k3s -n 50 --no-pager || true
        exit 1
    fi
done

echo "[LOG] - Token trouvé, copie vers /vagrant_shared/token"
sudo cp "$TOKEN_PATH" /vagrant_shared/token
sudo chmod 644 /vagrant_shared/token
ls -l /vagrant_shared/token || true

# alias k + kubeconfig
echo 'export PATH="/sbin:$PATH"' >> "$HOME/.bashrc"
echo "alias k='kubectl'" | sudo tee /etc/profile.d/00-aliases.sh > /dev/null
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> "$HOME/.bashrc"
