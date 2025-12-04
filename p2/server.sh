#!/bin/bash
sudo dnf update -y
sudo dnf install -y net-tools
sudo systemctl disable firewalld --now

# selinux settings
sudo setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

# in case of reboot or re-provisioning
sudo kill $( lsof -i:6443 -t )
/usr/local/bin/k3s-uninstall.sh

echo "Installing k3s ..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip 192.168.56.110 --write-kubeconfig-mode 0644" sh -s -

export PATH=$PATH:/usr/local/bin/
sudo chmod 777 /etc/rancher/k3s/k3s.yaml
sudo dnf install bash-completion
echo 'alias k="kubectl"' >> /home/vagrant/.bashrc
echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
echo 'complete -o default -F __start_kubectl k' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc


kubectl wait --for=condition=Ready node/vmasses
echo "Master-plane ready"

echo "Creating pods ..."
kubectl apply -f /vagrant/deployments.yaml
echo "Creating services ..."
kubectl apply -f /vagrant/services.yaml
echo "Applying ingress configuration ..."
kubectl apply -f /vagrant/ingress.yaml
sleep 125
echo "Server is up and running!"
kubectl get all
