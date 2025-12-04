# ==============================
# Makefile K3D + ArgoCD + GitOps
# ==============================

# Variables
CLUSTER_NAME := dev-cluster
ARGO_NAMESPACE := argocd
DEV_NAMESPACE := dev
APP_NAME := playground
APP_PORT := 8888
NODE_PORT := 30080
GITHUB_REPO := https://github.com/lseiberr/inception_of_things_p3
IMAGE := wil42/playground
IMAGE_TAG := v1
SSH_KEY := /home/vagrant/.ssh/id_rsa

# -------------------------
# Default target
# -------------------------
all: create_cluster setup_namespaces install_argocd deploy_app

# -------------------------
# Add SSH key to agent
# -------------------------
setup_ssh:
	@echo ">>> Adding SSH key to agent..."
	eval "$$(ssh-agent -s)" && ssh-add $(SSH_KEY)

# -------------------------
# Create K3D cluster
# -------------------------
create_cluster: setup_ssh
	@echo ">>> Creating K3D cluster..."
	k3d cluster create $(CLUSTER_NAME) --servers 1 --agents 2 -p "$(APP_PORT):$(NODE_PORT)@loadbalancer"
	kubectl get nodes

# -------------------------
# Create namespaces
# -------------------------
setup_namespaces:
	@echo ">>> Creating namespaces..."
	kubectl create namespace $(ARGO_NAMESPACE) || true
	kubectl create namespace $(DEV_NAMESPACE) || true

# -------------------------
# Install Argo CD (already CLI installed)
# -------------------------
install_argocd:
	@echo ">>> Installing ArgoCD..."
	kubectl apply -n $(ARGO_NAMESPACE) \
	  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo ">>> Port forwarding ArgoCD to localhost:8080..."
	kubectl port-forward svc/argocd-server -n $(ARGO_NAMESPACE) 8080:443 &

# -------------------------
# Deploy application from GitHub
# -------------------------
deploy_app: setup_ssh
	@echo ">>> Cloning repo..."
	mkdir -p tmp_app && cd tmp_app && git clone $(GITHUB_REPO) repo || true
	@echo ">>> Applying Kubernetes manifests..."
	cd tmp_app/repo && \
		kubectl apply -f app/deployment.yaml -n $(DEV_NAMESPACE) && \
		kubectl apply -f app/service.yaml -n $(DEV_NAMESPACE)
	@echo ">>> Application deployed to namespace $(DEV_NAMESPACE) on port $(APP_PORT)"

# -------------------------
# Update application version
# -------------------------
update_version:
	@echo ">>> Updating app version to $(IMAGE_TAG)..."
	kubectl -n $(DEV_NAMESPACE) set image deployment/$(APP_NAME) $(APP_NAME)=$(IMAGE):$(IMAGE_TAG)
	kubectl rollout status deployment/$(APP_NAME) -n $(DEV_NAMESPACE)
	@echo ">>> Application updated to $(IMAGE):$(IMAGE_TAG)"

# -------------------------
# Clean cluster
# -------------------------
clean:
	@echo ">>> Deleting K3D cluster..."
	k3d cluster delete $(CLUSTER_NAME)
	@echo ">>> Cleaned up."

.PHONY: all setup_ssh create_cluster setup_namespaces install_argocd deploy_app update_version clean
