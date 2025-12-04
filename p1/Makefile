SHELL := /bin/bash

VAGRANT_CWD := $(CURDIR)

.PHONY: help up halt destroy status ssh-server ssh-worker reload provision logs

help:
	@echo "Commandes disponibles :"
	@echo "  make up		 - Démarrer et provisionner les VMs (server + worker)"
	@echo "  make halt	   - Arrêter les VMs"
	@echo "  make destroy	- Détruire les VMs"
	@echo "  make status	 - Statut des VMs"
	@echo "  make reload	 - Redémarrer les VMs avec rechargement du Vagrantfile"
	@echo "  make provision  - Relancer le provisionning sur les VMs"
	@echo "  make ssh-server - SSH sur la VM server (userS)"
	@echo "  make ssh-worker - SSH sur la VM worker (userSW)"

up:
	VAGRANT_CWD=$(VAGRANT_CWD) vagrant up

halt:
	VAGRANT_CWD=$(VAGRANT_CWD) vagrant halt

destroy:
	VAGRANT_CWD=$(VAGRANT_CWD) vagrant destroy -f

status:
	VAGRANT_CWD=$(VAGRANT_CWD) vagrant status

reload:
	VAGRANT_CWD=$(VAGRANT_CWD) vagrant reload

provision:
	VAGRANT_CWD=$(VAGRANT_CWD) vagrant provision

ssh-server:
	VAGRANT_CWD=$(VAGRANT_CWD) vagrant ssh userS

ssh-worker:
	VAGRANT_CWD=$(VAGRANT_CWD) vagrant ssh userSW
