# Makefile

VM_NAME := YourLoginS
VM_IP   := 192.168.56.110

KUBECONFIG_PATH := /etc/rancher/k3s/k3s.yaml
APPS_FILE       := apps.yaml
INGRESS_FILE    := ingress.yaml

.PHONY: help up halt destroy status ssh k3s-setup k8s-apply k8s-clean logs

help:
    @echo "Cibles disponibles :"
    @echo "  make up        : Démarrer la VM Vagrant et provisionner K3s"
    @echo "  make halt      : Arrêter la VM"
    @echo "  make destroy   : Détruire la VM"
    @echo "  make status    : Statut de la VM"
    @echo "  make ssh       : Se connecter en SSH à la VM"
    @echo "  make k8s-apply : Déployer les apps et l'ingress sur K3s"
    @echo "  make k8s-clean : Supprimer les ressources apps + ingress"
    @echo "  make logs      : Logs du contrôleur ingress (Traefik)"

up:
    vagrant up

halt:
    vagrant halt

destroy:
    vagrant destroy -f

status:
    vagrant status

ssh:
    vagrant ssh

k8s-apply:
    vagrant ssh -c "export KUBECONFIG=$(KUBECONFIG_PATH) && \
      kubectl apply -f /vagrant/$(APPS_FILE) && \
      kubectl apply -f /vagrant/$(INGRESS_FILE) && \
      kubectl get pods,svc,ingress -n apps"

k8s-clean:
    vagrant ssh -c "export KUBECONFIG=$(KUBECONFIG_PATH) && \
      kubectl delete -f /vagrant/$(INGRESS_FILE) --ignore-not-found && \
      kubectl delete -f /vagrant/$(APPS_FILE) --ignore-not-found"

logs:
    vagrant ssh -c "export KUBECONFIG=$(KUBECONFIG_PATH) && \
      kubectl logs -n kube-system -l app=traefik -f"
