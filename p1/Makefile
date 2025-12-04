# Environnement K3s avec Vagrant

Ce projet crée une VM Vagrant avec K3s (mode serveur) et déploie 3 applications web accessibles en fonction du `Host` utilisé.

## Prérequis

- macOS
- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- `make`

## Structure du projet

- `Vagrantfile` : configuration de la VM (Ubuntu + K3s)
- `apps.yaml`   : déploiement Kubernetes pour `app1`, `app2`, `app3`
- `ingress.yaml`: Ingress Traefik avec routage selon le `Host`
- `Makefile`    : commandes pratiques

## VM

- Nom d’hôte : `YourLoginS` (à adapter dans le `Vagrantfile`)
- IP privée : `192.168.56.110`

## Démarrage de l’environnement

Dans le dossier du projet :

```bash
make up
