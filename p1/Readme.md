# Cluster K3s avec Vagrant (server + worker)

Ce projet crée un petit cluster K3s avec 2 VMs Vagrant :
- `userS` : nœud **server** K3s (IP `192.168.56.110`)
- `userSW` : nœud **worker** K3s (IP `192.168.56.111`)

Le token du serveur est copié sur le dossier partagé et utilisé par le script `agent.sh` pour joindre le worker au cluster.

## Prérequis

- macOS / Linux / Windows
- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- `make`

## Fichiers

- `Vagrantfile` : définition des VMs `lseiberrS` et `lseiberrSW`
- `server.sh`   : installation de K3s en **mode server** + kubectl
- `agent.sh`    : installation de K3s en **mode agent** (worker) + kubectl
- `Makefile`    : commandes pratiques pour gérer les VMs

## Démarrage

Dans le dossier `p1` :

```bash
vagrant up
```

Regarder si la vm utilise eth1

```bash
ifconfig enp0s6
```
