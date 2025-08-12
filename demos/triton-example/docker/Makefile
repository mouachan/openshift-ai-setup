# Makefile optimisé pour Triton Demo Notebook
# Commandes rapides pour build et déploiement

.PHONY: help build build-quick deploy test clean gitops-deploy gitops-status

help: ## Afficher l'aide
	@echo "🚀 Commandes disponibles:"
	@echo "  make build        - Build complet de l'image"
	@echo "  make build-quick  - Build rapide avec cache"
	@echo "  make deploy       - Déploiement du workbench"
	@echo "  make test         - Test de connexion"
	@echo "  make clean        - Nettoyage des images"
	@echo "  make all          - Build + Deploy + Test"
	@echo ""
	@echo "🔄 Commandes GitOps:"
	@echo "  make gitops-deploy - Déploiement via GitOps"
	@echo "  make gitops-status - Statut GitOps et ArgoCD"

build: ## Build complet de l'image
	@echo "🔨 Build complet..."
	podman build --tag=quay.io/mouachan/triton-demo-notebook:latest --file=Containerfile .
	podman push quay.io/mouachan/triton-demo-notebook:latest

build-quick: ## Build rapide avec cache
	@echo "⚡ Build rapide..."
	./build-optimized.sh

deploy: ## Déploiement du workbench
	@echo "🚀 Déploiement..."
	./deploy-quick.sh

test: ## Test de connexion
	@echo "🧪 Test de connexion..."
	oc get pods -n triton-demo -l app=triton-workbench
	@echo "📊 Statut du workbench:"
	oc get route -n triton-demo | grep triton-workbench || echo "⚠️ Route non trouvée"

clean: ## Nettoyage des images
	@echo "🧹 Nettoyage..."
	podman rmi quay.io/mouachan/triton-demo-notebook:latest || true
	podman image prune -f

all: build-quick deploy test ## Tout faire: Build + Deploy + Test
	@echo "🎉 Opération complète terminée!"

# Commandes GitOps
gitops-deploy: ## Déploiement via GitOps
	@echo "🔄 Déploiement GitOps..."
	cd ../../.. && ./scripts/deploy-triton-demo-gitops.sh

gitops-status: ## Statut GitOps et ArgoCD
	@echo "🔍 Vérification du statut GitOps..."
	cd ../../.. && ./scripts/check-gitops-status.sh

# Commandes de développement rapide
dev-build: ## Build de développement (sans push)
	@echo "🔨 Build de développement..."
	podman build --tag=triton-demo-notebook:dev --file=Containerfile .

dev-test: ## Test local de l'image
	@echo "🧪 Test local..."
	podman run --rm triton-demo-notebook:dev python -c "import jupyter, jupyterlab, elyra, numpy, pandas, sklearn, matplotlib, kfp; print('✅ OK')"

# Commandes de diagnostic
status: ## Statut du cluster
	@echo "📊 Statut du cluster:"
	oc get pods -n triton-demo
	oc get routes -n triton-demo

logs: ## Logs du workbench
	@echo "📝 Logs du workbench:"
	oc logs -n triton-demo -l app=triton-workbench --tail=50 -c triton-workbench
