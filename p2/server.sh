#!/bin/bash
set -e

sudo dnf update -y || true
sudo dnf install -y net-tools lsof || true
sudo systemctl disable firewalld --now || true

# selinux settings (si présent)
if [ -f /etc/selinux/config ]; then
  sudo setenforce 0 || true
  sudo sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config || true
fi

# en cas de reboot ou reprovision
sudo kill "$(lsof -i:6443 -t)" 2>/dev/null || true
/usr/local/bin/k3s-uninstall.sh 2>/dev/null || true

echo "Installing k3s ..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip 192.168.56.110 --write-kubeconfig-mode 0644" sh -s -

export PATH=$PATH:/usr/local/bin/
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
sudo dnf install -y bash-completion || true
echo 'alias k="kubectl"' >> /home/vagrant/.bashrc
echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
echo 'complete -o default -F __start_kubectl k' >> /home/vagrant/.bashrc

# attendre que le node (lseiberrS) soit prêt
kubectl wait --for=condition=Ready node/lseiberrs --timeout=120s || true
echo "Master-plane ready"

echo "Creating deployments ..."
kubectl apply -f /vagrant/deployments.yaml
echo "Creating services ..."
kubectl apply -f /vagrant/services.yaml
echo "Applying ingress configuration ..."
kubectl apply -f /vagrant/ingress.yaml

sleep 30
echo "Server is up and running!"
kubectl get all -A
