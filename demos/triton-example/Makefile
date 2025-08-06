# Makefile pour la démo Triton Inference
.PHONY: help setup install-deps run-pipeline run-notebook deploy undeploy test status logs clean

# Variables
PYTHON = python3
VENV = venv
NAMESPACE = rhods-notebooks
MODEL_NAME = iris-classifier-triton

# Couleurs pour l'affichage
BLUE = \033[0;34m
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## Affiche cette aide
	@echo "$(BLUE)Démo Triton Inference - Commandes disponibles:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Exemples d'utilisation:$(NC)"
	@echo "  make setup             # Configuration de l'environnement"
	@echo "  make run-pipeline      # Exécution du pipeline ML"
	@echo "  make deploy-model      # Déploiement du modèle"
	@echo "  make test              # Test d'inférence"
	@echo "  make demo-local        # Démo locale complète"

setup-complete: ## Configuration GitOps complète de l'environnement (OBSOLÈTE)
	@echo "$(YELLOW)⚠️  Cette commande est obsolète$(NC)"
	@echo "$(BLUE)Le GitOps est maintenant intégré dans le GitOps principal$(NC)"
	@echo "$(BLUE)Utilisez: oc apply -f ../../argocd-apps/openshift-ai-application.yaml$(NC)"

deploy-gitops: ## Déploiement GitOps du Data Science Project (OBSOLÈTE)
	@echo "$(YELLOW)⚠️  Cette commande est obsolète$(NC)"
	@echo "$(BLUE)Le GitOps est maintenant intégré dans le GitOps principal$(NC)"

deploy-gitops-complete: ## Déploiement GitOps complet en une fois (OBSOLÈTE)
	@echo "$(YELLOW)⚠️  Cette commande est obsolète$(NC)"
	@echo "$(BLUE)Le GitOps est maintenant intégré dans le GitOps principal$(NC)"

undeploy-gitops: ## Suppression du déploiement GitOps (OBSOLÈTE)
	@echo "$(YELLOW)⚠️  Cette commande est obsolète$(NC)"
	@echo "$(BLUE)Le GitOps est maintenant intégré dans le GitOps principal$(NC)"

status-gitops: ## Statut du déploiement GitOps (OBSOLÈTE)
	@echo "$(YELLOW)⚠️  Cette commande est obsolète$(NC)"
	@echo "$(BLUE)Utilisez: oc get all -n triton-demo$(NC)"

configure-elyra: ## Configuration d'Elyra pour les pipelines
	@echo "$(BLUE)🔧 Configuration Elyra...$(NC)"
	$(PYTHON) scripts/configure_elyra.py configure
	@echo "$(GREEN)✅ Elyra configuré$(NC)"

verify-elyra: ## Vérification de la configuration Elyra
	@echo "$(BLUE)🔍 Vérification Elyra...$(NC)"
	$(PYTHON) scripts/configure_elyra.py verify

validate-gitops: ## Validation complète de la configuration GitOps (OBSOLÈTE)
	@echo "$(YELLOW)⚠️  Cette commande est obsolète$(NC)"
	@echo "$(BLUE)Le GitOps est maintenant intégré dans le GitOps principal$(NC)"

validate-quick: ## Validation rapide de la configuration (OBSOLÈTE)
	@echo "$(YELLOW)⚠️  Cette commande est obsolète$(NC)"
	@echo "$(BLUE)Le GitOps est maintenant intégré dans le GitOps principal$(NC)"

setup: ## Configuration complète de l'environnement
	@echo "$(BLUE)🔧 Configuration de l'environnement...$(NC)"
	./scripts/setup.sh venv
	@echo "$(GREEN)✅ Configuration terminée$(NC)"
	@echo "$(YELLOW)Prochaine étape: make run-pipeline$(NC)"

install-deps: ## Installation des dépendances Python
	@echo "$(BLUE)📦 Installation des dépendances...$(NC)"
	$(PYTHON) -m pip install --upgrade pip
	$(PYTHON) -m pip install -r requirements.txt
	@echo "$(GREEN)✅ Dépendances installées$(NC)"

venv: ## Création de l'environnement virtuel
	@echo "$(BLUE)🐍 Création de l'environnement virtuel...$(NC)"
	$(PYTHON) -m venv $(VENV)
	@echo "$(GREEN)✅ Environnement virtuel créé$(NC)"
	@echo "$(YELLOW)Activez-le avec: source $(VENV)/bin/activate$(NC)"

run-pipeline: ## Exécution du pipeline Kubeflow complet
	@echo "$(BLUE)🚀 Lancement du pipeline Kubeflow...$(NC)"
	$(PYTHON) pipelines/iris_classification_pipeline.py
	@echo "$(GREEN)✅ Pipeline terminé$(NC)"

run-notebook: ## Lancement de Jupyter Notebook
	@echo "$(BLUE)📓 Lancement de Jupyter Notebook...$(NC)"
	jupyter notebook notebooks/
	@echo "$(GREEN)✅ Notebook fermé$(NC)"

preprocess: ## Exécution de la préparation des données
	@echo "$(BLUE)📊 Préparation des données...$(NC)"
	$(PYTHON) pipelines/data_preprocessing.py
	@echo "$(GREEN)✅ Données préparées$(NC)"

train: ## Exécution de l'entraînement du modèle
	@echo "$(BLUE)🤖 Entraînement du modèle...$(NC)"
	$(PYTHON) pipelines/model_training.py
	@echo "$(GREEN)✅ Modèle entraîné$(NC)"

register: ## Enregistrement du modèle dans Model Registry
	@echo "$(BLUE)📋 Enregistrement du modèle...$(NC)"
	$(PYTHON) pipelines/model_registry.py
	@echo "$(GREEN)✅ Modèle enregistré$(NC)"

deploy: deploy-model ## Déploiement du modèle avec Triton (legacy)

deploy-model: ## Déploiement du modèle avec Triton (OBSOLÈTE)
	@echo "$(YELLOW)⚠️  Cette commande est obsolète$(NC)"
	@echo "$(BLUE)Le déploiement se fait maintenant via le GitOps intégré$(NC)"
	@echo "$(BLUE)Utilisez: oc apply -k ../../components/instances/triton-demo-instance/base/model-serving/$(NC)"

undeploy: undeploy-model ## Suppression du déploiement (legacy)

undeploy-model: ## Suppression du déploiement du modèle (OBSOLÈTE)
	@echo "$(YELLOW)⚠️  Cette commande est obsolète$(NC)"
	@echo "$(BLUE)Le déploiement se fait maintenant via le GitOps intégré$(NC)"

status: ## Affichage du statut du déploiement (OBSOLÈTE)
	@echo "$(YELLOW)⚠️  Cette commande est obsolète$(NC)"
	@echo "$(BLUE)Utilisez: oc get all -n triton-demo$(NC)"

logs: ## Affichage des logs du déploiement (OBSOLÈTE)
	@echo "$(YELLOW)⚠️  Cette commande est obsolète$(NC)"
	@echo "$(BLUE)Utilisez: oc logs -l app.kubernetes.io/name=triton-demo -n triton-demo$(NC)"

test: ## Test d'inférence du modèle déployé
	@echo "$(BLUE)🧪 Test d'inférence...$(NC)"
	./scripts/test_inference.py

test-local: ## Test local des scripts Python
	@echo "$(BLUE)🧪 Test local des scripts...$(NC)"
	$(PYTHON) -c "import kfp, sklearn, tensorflow; print('✅ Dépendances OK')"
	$(PYTHON) -c "from pipelines.data_preprocessing import load_and_preprocess_data; print('✅ Script préprocessing OK')"
	$(PYTHON) -c "from pipelines.model_training import train_model; print('✅ Script training OK')"
	@echo "$(GREEN)✅ Tests locaux réussis$(NC)"

clean: ## Nettoyage des fichiers temporaires
	@echo "$(BLUE)🧹 Nettoyage...$(NC)"
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache/
	rm -rf models/temp/
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

clean-venv: ## Suppression de l'environnement virtuel
	@echo "$(BLUE)🗑️  Suppression de l'environnement virtuel...$(NC)"
	rm -rf $(VENV)
	@echo "$(GREEN)✅ Environnement virtuel supprimé$(NC)"

check-cluster: ## Vérification de la connexion au cluster
	@echo "$(BLUE)🔍 Vérification de la connexion au cluster...$(NC)"
	@oc whoami >/dev/null && echo "$(GREEN)✅ Connecté en tant que: $$(oc whoami)$(NC)" || echo "$(RED)❌ Non connecté au cluster$(NC)"
	@oc get namespace $(NAMESPACE) >/dev/null 2>&1 && echo "$(GREEN)✅ Namespace $(NAMESPACE) disponible$(NC)" || echo "$(RED)❌ Namespace $(NAMESPACE) non trouvé$(NC)"

check-prerequisites: ## Vérification des prérequis
	@echo "$(BLUE)🔍 Vérification des prérequis...$(NC)"
	@command -v $(PYTHON) >/dev/null && echo "$(GREEN)✅ Python3 disponible$(NC)" || echo "$(RED)❌ Python3 non trouvé$(NC)"
	@command -v oc >/dev/null && echo "$(GREEN)✅ OpenShift CLI disponible$(NC)" || echo "$(RED)❌ OpenShift CLI non trouvé$(NC)"
	@command -v jupyter >/dev/null && echo "$(GREEN)✅ Jupyter disponible$(NC)" || echo "$(YELLOW)⚠️  Jupyter non trouvé (installez avec: pip install jupyter)$(NC)"
	@command -v curl >/dev/null && echo "$(GREEN)✅ curl disponible$(NC)" || echo "$(YELLOW)⚠️  curl non trouvé$(NC)"

check-gitops: ## Vérification du statut du GitOps intégré
	@echo "$(BLUE)🔍 Vérification du GitOps intégré...$(NC)"
	@oc get application openshift-ai-complete -n openshift-gitops >/dev/null 2>&1 && echo "$(GREEN)✅ Application ArgoCD principale trouvée$(NC)" || echo "$(RED)❌ Application ArgoCD principale non trouvée$(NC)"
	@oc get namespace triton-demo >/dev/null 2>&1 && echo "$(GREEN)✅ Namespace triton-demo trouvé$(NC)" || echo "$(YELLOW)⚠️  Namespace triton-demo non trouvé (déployez d'abord le GitOps)$(NC)"
	@oc get all -n triton-demo --no-headers 2>/dev/null | wc -l | xargs -I {} echo "$(BLUE)📊 Ressources dans triton-demo: {}$(NC)" || echo "$(YELLOW)⚠️  Aucune ressource dans triton-demo$(NC)"

demo-complete: ## Démo GitOps complète (OBSOLÈTE)
	@echo "$(YELLOW)⚠️  Cette commande est obsolète$(NC)"
	@echo "$(BLUE)Le GitOps est maintenant intégré dans le GitOps principal$(NC)"
	@echo "$(BLUE)Utilisez: make demo-local pour la démo locale$(NC)"

demo: demo-local ## Démo locale (setup + pipeline + deploy + test) - legacy

demo-local: ## Démo locale (setup + pipeline + deploy + test)
	@echo "$(BLUE)🎯 DÉMO LOCALE TRITON INFERENCE$(NC)"
	@echo "$(BLUE)══════════════════════════════════$(NC)"
	$(MAKE) setup
	$(MAKE) run-pipeline
	$(MAKE) deploy-model
	$(MAKE) test
	@echo "$(GREEN)🎉 DÉMO LOCALE TERMINÉE AVEC SUCCÈS!$(NC)"

dev: ## Mode développement (setup + notebook)
	@echo "$(BLUE)👨‍💻 MODE DÉVELOPPEMENT$(NC)"
	$(MAKE) setup
	$(MAKE) run-notebook

# Règle par défaut
.DEFAULT_GOAL := help
