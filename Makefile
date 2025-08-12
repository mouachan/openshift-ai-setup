# 🚀 OpenShift AI Setup - Makefile
# 
# Commandes utiles pour gérer le projet OpenShift AI

.PHONY: help install clean verify status logs backup restore

# Variables
CLUSTER_DOMAIN ?= $(shell oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}' 2>/dev/null || echo "cluster.local")
NAMESPACE ?= triton-demo

# Couleurs pour l'affichage
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
RED := \033[0;31m
NC := \033[0m # No Color

# Aide par défaut
help: ## Afficher cette aide
	@echo "$(BLUE)🚀 OpenShift AI Setup - Commandes disponibles$(NC)"
	@echo ""
	@echo "$(YELLOW)Installation et déploiement:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Exemples:$(NC)"
	@echo "  make install          # Installation complète"
	@echo "  make status           # Vérifier l'état du cluster"
	@echo "  make logs             # Afficher les logs"
	@echo "  make clean            # Nettoyer le cluster"

# Installation complète
install: ## Installation complète d'OpenShift AI
	@echo "$(BLUE)🚀 Installation complète d'OpenShift AI...$(NC)"
	@./install.sh

# Installation des opérateurs uniquement
operators: ## Installer uniquement les opérateurs
	@echo "$(BLUE)📦 Installation des opérateurs...$(NC)"
	@oc apply -k components/operators/

# Installation de l'infrastructure
infrastructure: ## Installer l'infrastructure de base
	@echo "$(BLUE)🏗️  Installation de l'infrastructure...$(NC)"
	@oc apply -k components/instances/minio-instance/base/
	@oc apply -k components/instances/rhoai-instance/components/model-registry/
	@oc apply -k components/instances/rhoai-instance/components/custom-serving-runtimes/
	@oc apply -k components/instances/pipelines-instance/base/
	@oc apply -k components/instances/service-mesh-instance/base/ || echo "$(YELLOW)⚠️  Service Mesh déjà installé$(NC)"
	@oc apply -k components/instances/serverless-instance/base/

# Installation du workbench
workbench: ## Installer le workbench personnalisé
	@echo "$(BLUE)🖥️  Installation du workbench...$(NC)"
	@oc apply -k components/instances/triton-demo-instance/base/data-science-project/
	@echo "$(YELLOW)⏳ Attente que le workbench démarre...$(NC)"
	@oc wait --for=condition=Ready pod -l app=triton-workbench -n $(NAMESPACE) --timeout=300s
	@echo "$(BLUE)🔧 Configuration d'Elyra...$(NC)"
	@oc apply -f components/instances/triton-demo-instance/base/data-science-project/elyra-runtime-config.yaml
	@oc exec triton-workbench-0 -n $(NAMESPACE) -c triton-workbench -- python3 /opt/app-root/elyra-config/init-runtime.py

# Configuration GitOps
gitops: ## Configurer GitOps avec ArgoCD
	@echo "$(BLUE)🔄 Configuration GitOps...$(NC)"
	@oc apply -k argocd-apps/

# Vérification de l'état
status: ## Vérifier l'état du cluster
	@echo "$(BLUE)📊 État du cluster OpenShift AI$(NC)"
	@echo ""
	@echo "$(YELLOW)🔍 Workbench:$(NC)"
	@oc get pods -n $(NAMESPACE) -l app=triton-workbench 2>/dev/null || echo "$(RED)❌ Namespace $(NAMESPACE) non trouvé$(NC)"
	@echo ""
	@echo "$(YELLOW)🗄️  MinIO:$(NC)"
	@oc get pods -n minio 2>/dev/null || echo "$(RED)❌ Namespace minio non trouvé$(NC)"
	@echo ""
	@echo "$(YELLOW)📦 Model Registry:$(NC)"
	@oc get pods -n rhoai-model-registries 2>/dev/null || echo "$(RED)❌ Namespace rhoai-model-registries non trouvé$(NC)"
	@echo ""
	@echo "$(YELLOW)🔧 Pipelines:$(NC)"
	@oc get datasciencepipelinesapplications -A 2>/dev/null || echo "$(RED)❌ Aucun pipeline trouvé$(NC)"
	@echo ""
	@echo "$(YELLOW)🖼️  Images personnalisées:$(NC)"
	@oc get imagestreams -n redhat-ods-applications | grep triton 2>/dev/null || echo "$(YELLOW)⚠️  Aucune image Triton trouvée$(NC)"

# Logs des composants
logs: ## Afficher les logs des composants
	@echo "$(BLUE)📋 Logs des composants$(NC)"
	@echo ""
	@echo "$(YELLOW)📱 Workbench:$(NC)"
	@oc logs triton-workbench-0 -n $(NAMESPACE) -c triton-workbench --tail=20 2>/dev/null || echo "$(RED)❌ Workbench non disponible$(NC)"
	@echo ""
	@echo "$(YELLOW)🗄️  MinIO:$(NC)"
	@oc logs -n minio -l app=minio --tail=10 2>/dev/null || echo "$(RED)❌ MinIO non disponible$(NC)"

# Vérification de la connectivité
verify: ## Vérifier la connectivité des services
	@echo "$(BLUE)🔍 Vérification de la connectivité$(NC)"
	@echo ""
	@echo "$(YELLOW)🔗 Test des pipelines:$(NC)"
	@curl -s -o /dev/null -w "Pipelines: %{http_code}\n" "https://ds-pipeline-dspa-test-pipeline.apps.$(CLUSTER_DOMAIN)/api/v1/healthz" --insecure 2>/dev/null || echo "$(RED)❌ Pipelines non accessibles$(NC)"
	@echo ""
	@echo "$(YELLOW)🔗 Test MinIO:$(NC)"
	@curl -s -o /dev/null -w "MinIO: %{http_code}\n" "https://minio-api-minio.apps.$(CLUSTER_DOMAIN)/health/live" --insecure 2>/dev/null || echo "$(RED)❌ MinIO non accessible$(NC)"

# Sauvegarde de la configuration
backup: ## Sauvegarder la configuration actuelle
	@echo "$(BLUE)💾 Sauvegarde de la configuration...$(NC)"
	@mkdir -p backups/$(shell date +%Y%m%d-%H%M%S)
	@oc get all -n $(NAMESPACE) -o yaml > backups/$(shell date +%Y%m%d-%H%M%S)/$(NAMESPACE)-backup.yaml
	@oc get all -n minio -o yaml > backups/$(shell date +%Y%m%d-%H%M%S)/minio-backup.yaml
	@oc get all -n rhoai-model-registries -o yaml > backups/$(shell date +%Y%m%d-%H%M%S)/model-registry-backup.yaml
	@echo "$(GREEN)✅ Sauvegarde créée dans backups/$(shell date +%Y%m%d-%H%M%S)/$(NC)"

# Restauration de la configuration
restore: ## Restaurer une configuration sauvegardée
	@echo "$(YELLOW)⚠️  Spécifiez le dossier de sauvegarde: make restore BACKUP_DIR=backups/YYYYMMDD-HHMMSS$(NC)"
	@if [ -z "$(BACKUP_DIR)" ]; then \
		echo "$(RED)❌ BACKUP_DIR non spécifié$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🔄 Restauration depuis $(BACKUP_DIR)...$(NC)"
	@oc apply -f $(BACKUP_DIR)/$(NAMESPACE)-backup.yaml
	@oc apply -f $(BACKUP_DIR)/minio-backup.yaml
	@oc apply -f $(BACKUP_DIR)/model-registry-backup.yaml
	@echo "$(GREEN)✅ Restauration terminée$(NC)"

# Nettoyage du cluster
clean: ## Nettoyer le cluster (supprimer tous les composants)
	@echo "$(RED)⚠️  ATTENTION: Cette action va supprimer tous les composants !$(NC)"
	@read -p "Êtes-vous sûr ? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "$(BLUE)🧹 Nettoyage du cluster...$(NC)"
	@oc delete -k components/instances/triton-demo-instance/base/data-science-project/ --ignore-not-found
	@oc delete -k components/instances/minio-instance/base/ --ignore-not-found
	@oc delete -k components/instances/rhoai-instance/components/model-registry/ --ignore-not-found
	@oc delete -k components/instances/rhoai-instance/components/custom-serving-runtimes/ --ignore-not-found
	@oc delete -k components/instances/pipelines-instance/base/ --ignore-not-found
	@oc delete -k components/instances/service-mesh-instance/base/ --ignore-not-found
	@oc delete -k components/instances/serverless-instance/base/ --ignore-not-found
	@oc delete -k argocd-apps/ --ignore-not-found
	@echo "$(GREEN)✅ Cluster nettoyé$(NC)"

# Nettoyage partiel (workbench uniquement)
clean-workbench: ## Nettoyer uniquement le workbench
	@echo "$(BLUE)🧹 Nettoyage du workbench...$(NC)"
	@oc delete -k components/instances/triton-demo-instance/base/data-science-project/ --ignore-not-found
	@echo "$(GREEN)✅ Workbench nettoyé$(NC)"

# Redémarrage du workbench
restart-workbench: ## Redémarrer le workbench
	@echo "$(BLUE)🔄 Redémarrage du workbench...$(NC)"
	@oc delete notebook triton-workbench -n $(NAMESPACE) --ignore-not-found
	@oc apply -k components/instances/triton-demo-instance/base/data-science-project/
	@echo "$(YELLOW)⏳ Attente que le workbench redémarre...$(NC)"
	@oc wait --for=condition=Ready pod -l app=triton-workbench -n $(NAMESPACE) --timeout=300s
	@echo "$(BLUE)🔧 Reconfiguration d'Elyra...$(NC)"
	@oc exec triton-workbench-0 -n $(NAMESPACE) -c triton-workbench -- python3 /opt/app-root/elyra-config/init-runtime.py
	@echo "$(GREEN)✅ Workbench redémarré$(NC)"

# Mise à jour de la configuration
update: ## Mettre à jour la configuration
	@echo "$(BLUE)🔄 Mise à jour de la configuration...$(NC)"
	@oc apply -k components/instances/triton-demo-instance/base/data-science-project/
	@oc apply -k components/instances/minio-instance/base/
	@oc apply -k components/instances/rhoai-instance/components/model-registry/
	@oc apply -k components/instances/rhoai-instance/components/custom-serving-runtimes/
	@echo "$(GREEN)✅ Configuration mise à jour$(NC)"

# Test des fonctionnalités
test: ## Tester les fonctionnalités principales
	@echo "$(BLUE)🧪 Tests des fonctionnalités...$(NC)"
	@echo "$(YELLOW)📱 Test du workbench:$(NC)"
	@oc get pods -n $(NAMESPACE) -l app=triton-workbench | grep -q "Running" && echo "$(GREEN)✅ Workbench fonctionnel$(NC)" || echo "$(RED)❌ Workbench non fonctionnel$(NC)"
	@echo "$(YELLOW)🗄️  Test de MinIO:$(NC)"
	@oc get pods -n minio | grep -q "Running" && echo "$(GREEN)✅ MinIO fonctionnel$(NC)" || echo "$(RED)❌ MinIO non fonctionnel$(NC)"
	@echo "$(YELLOW)🔧 Test des pipelines:$(NC)"
	@oc get datasciencepipelinesapplications -A | grep -q "dspa" && echo "$(GREEN)✅ Pipelines disponibles$(NC)" || echo "$(RED)❌ Pipelines non disponibles$(NC)"

# Affichage des informations de connexion
info: ## Afficher les informations de connexion
	@echo "$(BLUE)🔗 Informations de connexion$(NC)"
	@echo ""
	@echo "$(YELLOW)📱 Workbench:$(NC)"
	@WORKBENCH_ROUTE=$$(oc get route triton-workbench -n $(NAMESPACE) -o jsonpath='{.spec.host}' 2>/dev/null || echo "En cours de création"); \
	echo "  https://$$WORKBENCH_ROUTE"
	@echo ""
	@echo "$(YELLOW)🗄️  MinIO:$(NC)"
	@MINIO_ROUTE=$$(oc get route minio-api -n minio -o jsonpath='{.spec.host}' 2>/dev/null || echo "En cours de création"); \
	echo "  API: https://$$MINIO_ROUTE"
	@MINIO_CONSOLE_ROUTE=$$(oc get route minio-console -n minio -o jsonpath='{.spec.host}' 2>/dev/null || echo "En cours de création"); \
	echo "  Console: https://$$MINIO_CONSOLE_ROUTE"
	@echo ""
	@echo "$(YELLOW)📚 Documentation:$(NC)"
	@echo "  README.md - Guide complet"
	@echo "  docs/QUICK-START.md - Démarrage rapide"
	@echo "  docs/MODULAR-ARCHITECTURE.md - Architecture"

# Validation de la configuration
validate: ## Valider la configuration YAML
	@echo "$(BLUE)✅ Validation de la configuration...$(NC)"
	@for file in $$(find components/ -name "*.yaml" -o -name "*.yml"); do \
		echo "Validating $$file..."; \
		oc apply --dry-run=client -f $$file > /dev/null 2>&1 && echo "$(GREEN)✅ $$file$(NC)" || echo "$(RED)❌ $$file$(NC)"; \
	done
	@for file in $$(find argocd-apps/ -name "*.yaml" -o -name "*.yml"); do \
		echo "Validating $$file..."; \
		oc apply --dry-run=client -f $$file > /dev/null 2>&1 && echo "$(GREEN)✅ $$file$(NC)" || echo "$(RED)❌ $$file$(NC)"; \
	done

# Défaut
.DEFAULT_GOAL := help