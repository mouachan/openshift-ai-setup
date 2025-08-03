# Makefile pour OpenShift AI 2.22 - Version GitOps COMPLETE
# Toutes les fonctionnalités officielles d'OpenShift AI 2.22

.PHONY: help gitops-deploy quick-deploy status verify clean cleanup-all cleanup-safe

# Configuration
NAMESPACE ?= redhat-ods-applications
CURRENT_USER := $(shell oc whoami 2>/dev/null || echo "unknown")

help: ## Afficher l'aide
	@echo "🚀 OpenShift AI 2.22 - Déploiement GitOps COMPLET"
	@echo ""
	@echo "Commandes disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Utilisateur connecté: $(CURRENT_USER)"

gitops-deploy: ## 🎯 Déploiement GitOps COMPLET avec toutes les fonctionnalités
	@echo "🚀 Déploiement GitOps COMPLET OpenShift AI 2.22"
	@echo "Fonctionnalités incluses:"
	@echo "  ✅ Data Science Dashboard"
	@echo "  ✅ Jupyter Workbenches"
	@echo "  ✅ Model Serving (KServe + ModelMesh)"
	@echo "  ✅ Data Science Pipelines (Kubeflow)"
	@echo "  ✅ Distributed Workloads (CodeFlare)"
	@echo "  ✅ Ray Framework"
	@echo "  ✅ Model Registry"
	@echo "  ✅ Training Operator (PyTorch, TensorFlow, XGBoost)"
	@echo "  ✅ TrustyAI (Explainable AI)"
	@echo "  ✅ Kueue (Job Queueing)"
	@echo "  ✅ Service Mesh (Istio)"
	@echo "  ✅ Serverless (Knative)"
	@echo ""
	@bash gitops-deploy.sh

quick-deploy: ## ⚡ Déploiement rapide (préservé pour compatibilité)
	@echo "ℹ️ Recommandation: Utilisez 'make gitops-deploy' pour toutes les fonctionnalités"
	@bash quick-deploy.sh

status: ## 📊 Vérifier le statut du déploiement
	@echo "=== Status OpenShift AI 2.22 ==="
	@echo ""
	@echo "🔧 Operators:"
	@oc get csv -n openshift-operators | grep -E "(rhods|servicemesh|serverless|pipelines)" || echo "Aucun operator trouvé"
	@echo ""
	@echo "🎯 Instances RHOAI:"
	@oc get dsc,dsci -o wide 2>/dev/null || echo "Instances en cours de création..."
	@echo ""
	@echo "🕸️ Service Mesh:"
	@oc get smcp,smmr -n istio-system 2>/dev/null || echo "Service Mesh non configuré"
	@echo ""
	@echo "⚡ Serverless:"
	@oc get knativeserving,knativeeventing -A 2>/dev/null || echo "Serverless non configuré"
	@echo ""
	@echo "📊 Model Registry:"
	@oc get modelregistry -n $(NAMESPACE) 2>/dev/null || echo "Model Registry non configuré"
	@echo ""
	@echo "🛡️ TrustyAI:"
	@oc get trustyaiservice -n $(NAMESPACE) 2>/dev/null || echo "TrustyAI non configuré"
	@echo ""
	@echo "📋 Kueue:"
	@oc get clusterqueue,localqueue 2>/dev/null || echo "Kueue non configuré"
	@echo ""
	@echo "🌐 Dashboard URL:"
	@oc get route rhods-dashboard -n $(NAMESPACE) -o jsonpath='https://{.spec.host}' 2>/dev/null && echo "" || echo "Dashboard en cours de déploiement..."

verify: ## ✅ Vérifier toutes les fonctionnalités
	@echo "=== Vérification complète OpenShift AI 2.22 ==="
	@echo ""
	@echo "🔍 Test de connectivité dashboard..."
	@dashboard_url=$$(oc get route rhods-dashboard -n $(NAMESPACE) -o jsonpath='{.spec.host}' 2>/dev/null); \
	if [ -n "$$dashboard_url" ]; then \
		if curl -k -s --connect-timeout 10 "https://$$dashboard_url" > /dev/null; then \
			echo "✅ Dashboard accessible à https://$$dashboard_url"; \
		else \
			echo "⚠️ Dashboard trouvé mais non accessible: https://$$dashboard_url"; \
		fi; \
	else \
		echo "❌ Dashboard non trouvé"; \
	fi
	@echo ""
	@echo "🔍 Vérification des composants obligatoires..."
	@for component in dashboard workbenches model-serving data-science-pipelines distributed-workloads ray codeflare kserve modelmesh; do \
		if oc get dsc default-dsc -o jsonpath="{.spec.components.$$component.managementState}" 2>/dev/null | grep -q "Managed"; then \
			echo "✅ $$component: Managed"; \
		else \
			echo "⚠️ $$component: Non configuré"; \
		fi; \
	done
	@echo ""
	@echo "🔍 Vérification des composants avancés..."
	@for component in trustyai modelregistry trainingoperator kueue; do \
		if oc get dsc default-dsc -o jsonpath="{.spec.components.$$component.managementState}" 2>/dev/null | grep -q "Managed"; then \
			echo "✅ $$component: Managed"; \
		else \
			echo "⚠️ $$component: Non configuré"; \
		fi; \
	done
	@echo ""
	@echo "🔍 Utilisateurs configurés:"
	@oc get secret htpass-secret -n openshift-config -o jsonpath='{.data.htpasswd}' 2>/dev/null | base64 -d | cut -d: -f1 | while read user; do echo "  - $$user"; done || echo "❌ Aucun utilisateur HTPasswd trouvé"

clean: cleanup-safe ## 🧹 Nettoyage sécurisé (alias pour cleanup-safe)

cleanup-safe: ## 🧹 Nettoyage sécurisé (préserve l'utilisateur actuel)
	@echo "🧹 Nettoyage sécurisé OpenShift AI..."
	@echo "⚠️ L'utilisateur actuel ($(CURRENT_USER)) sera préservé"
	@read -p "Continuer? [y/N] " -n 1 -r; \
	echo ""; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "🗑️ Suppression des instances..."; \
		oc delete dsc --all --ignore-not-found=true; \
		oc delete dsci --all --ignore-not-found=true; \
		echo "🗑️ Suppression des instances avancées..."; \
		oc delete modelregistry --all -n $(NAMESPACE) --ignore-not-found=true; \
		oc delete trustyaiservice --all -n $(NAMESPACE) --ignore-not-found=true; \
		oc delete pytorchjob --all -n $(NAMESPACE) --ignore-not-found=true; \
		oc delete smcp --all -n istio-system --ignore-not-found=true; \
		oc delete smmr --all -n istio-system --ignore-not-found=true; \
		oc delete knativeserving --all --ignore-not-found=true; \
		oc delete knativeeventing --all --ignore-not-found=true; \
		echo "✅ Nettoyage terminé (utilisateur préservé)"; \
	else \
		echo "❌ Nettoyage annulé"; \
	fi

cleanup-all: ## 💥 Nettoyage COMPLET (⚠️ DANGER: supprime tout)
	@echo "💥 DANGER: Nettoyage COMPLET OpenShift AI"
	@echo "⚠️ Cela supprimera TOUS les utilisateurs et configurations"
	@echo "⚠️ L'utilisateur actuel ($(CURRENT_USER)) sera aussi supprimé!"
	@read -p "Êtes-vous ABSOLUMENT sûr? Tapez 'DELETE_ALL' pour confirmer: " -r; \
	if [[ $$REPLY == "DELETE_ALL" ]]; then \
		echo "💥 Suppression COMPLÈTE en cours..."; \
		oc delete dsc --all --ignore-not-found=true; \
		oc delete dsci --all --ignore-not-found=true; \
		oc delete csv -n openshift-operators -l operators.coreos.com/rhods-operator.openshift-operators --ignore-not-found=true; \
		oc delete subscription -n openshift-operators rhods-operator --ignore-not-found=true; \
		oc delete namespace redhat-ods-monitoring redhat-ods-operator redhat-ods-applications --ignore-not-found=true; \
		oc delete oauth cluster --ignore-not-found=true; \
		oc delete secret htpass-secret -n openshift-config --ignore-not-found=true; \
		oc delete clusterrolebinding mouachan-cluster-admin rhods-admins --ignore-not-found=true; \
		echo "💥 Suppression COMPLÈTE terminée!"; \
	else \
		echo "❌ Suppression annulée (heureusement!)"; \
	fi

# Aliases pour compatibilité
deploy: gitops-deploy
install: gitops-deploy
setup: gitops-deploy
