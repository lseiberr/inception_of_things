```markdown
# Inception of Things – Bonus
## Cluster k3d + GitLab + Argo CD

Ce bonus met en place, via Vagrant, un environnement complet de CI/CD local basé sur :

- **k3d** (Kubernetes dans Docker)
- **Traefik** comme Ingress Controller
- **GitLab** auto‑hébergé dans le cluster
- **Argo CD** pour le déploiement GitOps d’une application depuis GitLab

---

## 1. Prérequis

- Parallels + Vagrant installés
- Fichier `hosts` de ta machine modifié pour pointer vers la VM :

```bash
sudo /etc/hosts
```

Ajouter :

```text
192.168.56.111 gitlab.local
192.168.56.111 argocd.local
```

---

## 2. Démarrage de l’environnement

Depuis le dossier `bonus/` :

```bash
vagrant up
```

Le `Vagrantfile` :

- crée une VM Ubuntu 22.04 (`bento/ubuntu-22.04`)
- IP privée : `192.168.56.111`
- ports forwardés :
	- `8080` (HTTP Traefik) → `8081` sur l’hôte
	- `8443` (HTTPS Traefik) → `8443` sur l’hôte
- exécute le script `server.sh` en provisionning.

---

## 3. Ce que fait `server.sh`

### 3.1. Setup de base

- `apt-get update/upgrade`
- installation de quelques outils : `jq`, `curl`, `git`, `bash-completion`, etc.
- configuration git globale :
	```bash
	git config --global user.email "root@gitlab.local"
	git config --global user.name "Gitlab Root"
	```

### 3.2. Docker + k3d + kubectl

- installation de Docker CE, activation du service et ajout de l’utilisateur `vagrant` au groupe `docker`
- installation de `kubectl` (version stable)
- complétion bash / alias `k` pour `kubectl`
- installation de `k3d`

### 3.3. Création du cluster k3d

Cluster : `lseiberrs-cluster`

```bash
k3d cluster create lseiberrs-cluster \
	--servers 1 \
	--agents 1 \
	--port "8080:80@loadbalancer" \
	--port "8443:443@loadbalancer"
```

- expose Traefik (load balancer k3d) sur 8080/8443
- crée et configure le `KUBECONFIG` et le contexte `k3d-lseiberrs-cluster`
- vérifie les nœuds avec `kubectl get nodes`

### 3.4. Namespaces + Argo CD

Namespaces créés :

- `dev`
- `argocd`
- `gitlab`

Argo CD est installé via le manifeste officiel :

```bash
kubectl apply -n argocd \
	-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Ensuite, le déploiement `argocd-server` est patché pour être exposé en **HTTP simple** :

```bash
kubectl -n argocd patch deploy argocd-server \
	--type='json' \
	-p='[
		{
			"op": "add",
			"path": "/spec/template/spec/containers/0/args",
			"value": ["/usr/local/bin/argocd-server", "--staticassets", "/shared/app", "--insecure"]
		}
	]'
```

### 3.5. GitLab via Helm

- installation de Helm si nécessaire
- ajout du repo charts GitLab (`gitlab/gitlab`)
- installation via :

```bash
helm upgrade --install gitlab gitlab/gitlab \
	--namespace gitlab \
	-f /vagrant/gitlab-values.yaml \
	--timeout 30m \
	--set global.hosts.domain=gitlab.local \
	--set global.hosts.externalIP=192.168.56.111
```

`gitlab-values.yaml` désactive notamment :

- l’ingress NGINX de GitLab (on garde **Traefik** de k3d)
- GitLab Runner
- Prometheus

---

## 4. Ingress GitLab et Argo CD

### 4.1. Ingress GitLab

Fichier : `ingress-gitlab.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
	name: gitlab-ingress
	namespace: gitlab
	annotations:
		kubernetes.io/ingress.class: traefik
spec:
	rules:
		- host: gitlab.local
			http:
				paths:
					- path: /
						pathType: Prefix
						backend:
							service:
								name: gitlab-webservice-default
								port:
									number: 8080
```

Cet Ingress expose GitLab sur `http://gitlab.local` via Traefik.

> Attention : adapter `name: gitlab-webservice-default` si la release Helm crée un service avec un nom différent (`kubectl -n gitlab get svc`).

### 4.2. Ingress Argo CD

Fichier : `ingress-argocd.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
	name: argocd-ingress
	namespace: argocd
	annotations:
		kubernetes.io/ingress.class: traefik
spec:
	rules:
		- host: argocd.local
			http:
				paths:
					- path: /
						pathType: Prefix
						backend:
							service:
								name: argocd-server
								port:
									number: 80
```

Expose Argo CD en HTTP sur `http://argocd.local`.

---

## 5. Création et configuration du dépôt GitLab

L’objectif est que **Argo CD** déploie automatiquement les manifests d’une app versionnée dans GitLab.

### 5.1. Récupérer le mot de passe root GitLab

Sur la VM :

```bash
vagrant ssh
sudo kubectl -n gitlab get secret
# chercher un secret type root password, par ex. gitlab-gitlab-initial-root-password
kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d; echo
```

Ensuite, depuis ton navigateur :

- ouvrir `http://gitlab.local:8080`
- login : `root`
- mot de passe : celui récupéré ci‑dessus

### 5.2. Création du dépôt GitLab

Dans GitLab :

1. Créer un projet :
	 - Namespace : `root`
	 - Nom du projet : `lseiberr_ception`
2. Cloner le dépôt sur ta machine hôte, par exemple :

	 ```bash
	 git clone http://gitlab.local/root/lseiberr_ception.git
	 cd lseiberr_ception
	 ```

3. Créer un dossier `k8s/` qui contiendra les manifests de ton application à déployer (namespace `dev`).

	 Exemple minimal :

	 ```bash
	 mkdir k8s
	 cat > k8s/deployment.yaml << 'EOF'
	 apiVersion: apps/v1
	 kind: Deployment
	 metadata:
		 name: demo-app
		 namespace: dev
	 spec:
		 replicas: 1
		 selector:
			 matchLabels:
				 app: demo-app
		 template:
			 metadata:
				 labels:
					 app: demo-app
			 spec:
				 containers:
					 - name: demo-app
						 image: nginx:stable
						 ports:
							 - containerPort: 80
	 EOF

	 cat > k8s/service.yaml << 'EOF'
	 apiVersion: v1
	 kind: Service
	 metadata:
		 name: demo-app
		 namespace: dev
	 spec:
		 selector:
			 app: demo-app
		 ports:
			 - port: 80
				 targetPort: 80
	 EOF
	 ```

4. Commit & push :

	 ```bash
	 git add .
	 git commit -m "Add k8s manifests for demo app"
	 git push origin main
	 ```

---

## 6. Argo CD : lien GitLab → Cluster

Le fichier `argocd-wil42-app.yaml` déclare une ressource `Application` Argo CD :

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
	name: wil-playground-gitlab
	namespace: argocd
spec:
	project: default
	source:
		repoURL: http://gitlab.local/root/k3d-argo-gitlab.git
		targetRevision: main
		path: k8s
	destination:
		server: https://kubernetes.default.svc
		namespace: dev
	syncPolicy:
		automated:
			selfHeal: true
			prune: true
```

- `repoURL` : URL HTTP du dépôt GitLab
- `path: k8s` : Argo CD lit les manifests dans le dossier `k8s/` à la racine du repo
- `destination` : cluster interne (`kubernetes.default.svc`), namespace `dev`
- `syncPolicy.automated` :
	- `selfHeal: true` : Argo CD corrige toute dérive manuelle
	- `prune: true` : supprime les ressources K8s retirées du repo

Ce manifeste est appliqué dans `server.sh` :

```bash
kubectl apply -n argocd -f /vagrant/argocd-wil42-app.yaml
```

---

## 7. Utilisation d’Argo CD

### 7.1. Accès UI

Navigateur → `http://argocd.local`

Mot de passe admin initial :

```bash
vagrant ssh
kubectl -n argocd get secret argocd-initial-admin-secret \
	-o jsonpath="{.data.password}" | base64 -d; echo
```

User : `admin`

### 7.2. Vérification de l’application

Dans l’UI Argo CD, tu dois voir l’application :

- `wil-playground-gitlab`

Statut attendu : **Synced** et **Healthy**.

Tu peux également vérifier côté CLI :

```bash
vagrant ssh
kubectl -n argocd get applications
kubectl -n dev get all
```

Les ressources définies dans `k8s/` doivent être présentes (ex: `demo-app` Deployment + Service).

### 7.3. Cycle GitOps

1. Modifier les manifests dans le repo GitLab (par ex. changer `replicas` ou l’image).
2. `git commit && git push`
3. Argo CD détecte la nouvelle révision Git et met à jour automatiquement le cluster (grâce à `syncPolicy.automated`).

Le cluster devient donc 100 % **déclaratif** : l’état K8s reflète en permanence le contenu Git.

---

## 8. Résumé

- `vagrant up` : provisioning VM + Docker + k3d + Traefik + GitLab + Argo CD.
- GitLab exposé sur `http://gitlab.local`, Argo CD sur `http://argocd.local`.
- Un dépôt GitLab `k3d-argo-gitlab` contient la description K8s de l’app dans `k8s/`.
- Argo CD suit ce dépôt et synchronise automatiquement l’état du cluster (`namespace dev`) avec Git.
- Toute modification poussée dans GitLab → déploiement automatique via Argo CD (workflow GitOps complet).


argocd repo add http://gitlab.local:8080/root/lseiberr_ception.git \
  --username <ton_user> \
  --password <ton_token_gitlab>
