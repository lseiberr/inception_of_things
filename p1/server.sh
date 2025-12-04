#!/bin/bash
sudo dnf update -y
sudo dnf install -y net-tools
sudo systemctl disable firewalld --now
sudo setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
sudo ufw disable
sudo kill $( lsof -i:6443 -t )
sudo /usr/local/bin/k3s-uninstall.sh
echo "Installing k3s ..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip 192.168.56.110 --write-kubeconfig-mode 0644 --token 12345" sh -s -
echo 'alias k="kubectl"' >> /home/vagrant/.bashrc
sudo chmod 777 /etc/rancher/k3s/k3s.yaml
source /home/vagrant/.bashrc
