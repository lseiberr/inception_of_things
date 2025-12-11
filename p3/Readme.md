```markdown
# k3d + Argo CD + Ingress – Playground de déploiement continu

## Objectif du projet

Mettre en place un environnement local de type **mini-plateforme Kubernetes** avec :

- **k3d** : Kubernetes dans Docker (cluster léger, jetable)
- **Argo CD** : GitOps / déploiement continu
- **Traefik + Ingress** : accès HTTP à Argo CD et à l’application
- Une application **`wil-playground`** déployée automatiquement depuis un dépôt Git,
	dont l’image Docker est hébergée sur votre **Docker Hub**.
	Le but est d’observer le **changement de tag d’image** (ex: `v1` → `v2`) se propager
	automatiquement via Argo CD.

---

## Prérequis

Sur votre machine hôte (Mac/Linux) :

- **Vagrant**
- Un provider de VM compatible (config fournie pour **Parallels**)
- Accès Internet

Aucun besoin d’installer Docker / kubectl en local : tout se fait dans la VM.

---

## Architecture

Dans la VM `lseiberrS` (Ubuntu 22.04) :

1. **Docker** est installé et configuré.
2. **k3d** crée un cluster Kubernetes :
	 - 1 server + 1 agent
	 - Ports exposés sur la VM :
		 - `8080` → HTTP Ingress (`host:8081` sur la machine hôte via Vagrant)
		 - `8443` → HTTPS Ingress (également forwardé)
3. **kubectl** est installé et configuré dans la VM (`alias k="kubectl"`).
4. **Namespaces** :
	 - `argocd` : pour les composants Argo CD
	 - `dev` : pour l’application `wil-playground`
5. **Argo CD** est déployé depuis le manifest officiel.
6. Argo CD est forcé en mode **HTTP** (`--insecure`) pour simplifier les tests.
7. Un **Ingress Traefik** expose l’UI Argo CD sur `argocd.local`.
8. Une ressource **Argo CD Application** (`argo-wil42-app.yaml`) pointe vers ce repo Git
	 pour déployer les manifests Kubernetes du dossier `k8s` dans le namespace `dev`.

---

## Fichiers importants

- `Vagrantfile`
	- Crée la VM `lseiberrS`
	- IP privée : `192.168.56.111`
	- Ports forwardés :
		- `8080` (VM) → `8081` (hôte)
		- `8443` (VM) → `8443` (hôte)
	- Provisionne la VM avec `server.sh`

- `server.sh`
	- Installe Docker / kubectl / k3d
	- Crée le cluster k3d `lseiberrs-cluster`
	- Installe Argo CD (+ patch `--insecure`)
	- Crée les namespaces `dev` et `argocd`
	- Applique :
		- `argocd-wil42-app.yaml` (Application Argo CD)
		- `ingress-argocd.yaml` (Ingress pour l’UI Argo CD)

- `argocd-wil42-app.yaml`
	- `kind: Application` (Argo CD)
	- `repoURL: https://github.com/lseiberr/k3d-argo-wil.git`
	- `path: k8s`
	- `destination.namespace: dev`
	- `syncPolicy.automated` + `selfHeal` + `prune`

- `ingress-argocd.yaml`
	- Ingress Traefik sur `argocd.local`
	- Backend : service `argocd-server` port `80` dans le namespace `argocd`

---

## Mise en route

### 1. Lancer la VM et le cluster

```bash
vagrant up
```

À la fin du provisionning, le cluster k3d, Argo CD, l’Application Argo CD et l’Ingress seront déployés.

Se connecter à la VM :

```bash
vagrant ssh
```

Vérifier le cluster :

```bash
kubectl get nodes
kubectl get ns
kubectl -n argocd get all
kubectl -n dev get all
```

---

### 2. Accès à Argo CD

Dans `/etc/hosts` de votre machine hôte, ajouter :

```text
192.168.56.111  argocd.local
```

Puis ouvrir dans un navigateur :

```text
http://argocd.local
```

Le mot de passe admin initial (depuis la VM) :

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
	-o jsonpath="{.data.password}" | base64 -d && echo
```

---

## Démonstration du changement de tag d’image

### 1. Manifests de l’application

Dans le repo Git cible (`k3d-argo-wil.git`), le dossier `k8s/` contient
les manifests de l’application `wil-playground` avec une spécification
d’image du type :

```yaml
spec:
	template:
		spec:
			containers:
				- name: wil-playground
					image: lseiberr/mon-image:TAG_COURANT
					ports:
						- containerPort: 80
```

### 2. Étapes pour voir le changement

1. **Build & push** une nouvelle version sur Docker Hub :

	 ```bash
	 docker build -t lseiberr/mon-image:v2 .
	 docker push lseiberr/mon-image:v2
	 ```

2. **Modifier le manifest** dans le repo Git (`k8s/deployment.yaml` par ex.) :

	 ```yaml
	 image: lseiberr/mon-image:v1
	 # devient
	 image: lseiberr/mon-image:v2
	 ```

3. **Commit & push** :

	 ```bash
	 git add k8s/deployment.yaml
	 git commit -m "chore: bump image to v2"
	 git push
	 ```

4. Dans l’UI **Argo CD** (`http://argocd.local:8080`), sur l’application `wil-playground` :
	 - Argo CD détecte le diff
	 - Comme `syncPolicy.automated` est activé, il applique automatiquement
		 le nouveau manifest.

5. Vérifier depuis la VM :

	 ```bash
	 kubectl -n dev describe deploy wil-playground | grep Image
	 ```

L’image doit maintenant pointer sur `…:v2`.

---

## Accès à l’application depuis la VM

Option simple avec port-forward (si un service `wil-playground` existe) :

```bash
kubectl -n dev port-forward svc/wil-playground 9090:80
curl -v http://127.0.0.1:9090/
```

---

## Reset / reprovision

Pour repartir sur un environnement propre :

```bash
vagrant destroy -f
vagrant up
```

Le script `server.sh` se charge de supprimer/créer le cluster k3d à
chaque reprovisionnement.
