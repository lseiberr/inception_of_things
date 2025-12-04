#!/bin/bash
sudo dnf update -y
sudo dnf install -y net-tools
sudo systemctl disable firewalld --now
sudo setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
sudo /usr/local/bin/k3s-agent-uninstall.sh
export TKN=$(cat /vagrant/token)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://192.168.56.110:6443 --node-ip 192.168.56.111 --token 12345" sh -s -
echo "Agent setup complete"
