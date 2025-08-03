# Makefile pour OpenShift AI 2.22 - GitOps avec ArgoCD

.PHONY: help deploy status verify clean

# Configuration
CURRENT_USER := $(shell oc whoami 2>/dev/null || echo "unknown")

help: ## Afficher l'aide
	@echo "🚀 OpenShift AI 2.22 - GitOps avec ArgoCD"
	@echo ""
	@echo "Commandes disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Utilisateur connecté: $(CURRENT_USER)"

deploy: ## 🚀 Déployer OpenShift AI via ArgoCD
	@echo "🚀 Déploiement OpenShift AI via ArgoCD"
	@echo "Repository: https://github.com/mouachan/openshift-ai-setup.git"
	@echo ""
	@echo "Installation GitOps si nécessaire..."
	@oc apply -f components/operators/gitops/base/subscription.yaml || true
	@echo "Attente de l'installation GitOps..."
	@sleep 30
	@echo ""
	@echo "Déploiement de l'application ArgoCD..."
	@oc apply -f argocd/openshift-ai-application.yaml
	@echo ""
	@echo "✅ Application ArgoCD créée !"
	@echo "🌐 Interface ArgoCD: https://$$(oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null || echo 'en-cours-installation')"

status: ## 📊 Vérifier le statut du déploiement
	@echo "=== Status OpenShift AI GitOps ==="
	@echo ""
	@echo "🎯 Applications ArgoCD:"
	@oc get applications -n openshift-gitops 2>/dev/null || echo "GitOps en cours d'installation"
	@echo ""
	@echo "🔧 Operators:"
	@oc get csv -n openshift-operators | grep -E "(rhods|servicemesh|serverless|pipelines|gitops)" || echo "En cours d'installation..."
	@echo ""
	@echo "🎯 OpenShift AI:"
	@oc get dsc,dsci -o wide 2>/dev/null || echo "En cours d'installation..."
	@echo ""
	@echo "🌐 URLs:"
	@echo "  ArgoCD: https://$$(oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null || echo 'installation-en-cours')"
	@echo "  OpenShift AI: https://$$(oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}' 2>/dev/null || echo 'installation-en-cours')"

verify: ## ✅ Vérifier que tout fonctionne
	@echo "=== Vérification complète ==="
	@echo ""
	@echo "🔍 Applications ArgoCD:"
	@oc get applications -n openshift-gitops --no-headers | awk '{print "  " $$1 " - " $$3 " - " $$4}' || echo "  Aucune application"
	@echo ""
	@echo "🔍 Pods OpenShift AI:"
	@oc get pods -n redhat-ods-applications --no-headers | wc -l | awk '{print "  " $$1 " pods actifs"}' 2>/dev/null || echo "  Namespace non créé"
	@echo ""
	@echo "🔍 Service Mesh:"
	@oc get smcp -n istio-system --no-headers | wc -l | awk '{print "  " $$1 " control plane(s)"}' 2>/dev/null || echo "  Non installé"
	@echo ""
	@echo "🔍 Knative:"
	@oc get knativeserving -n knative-serving --no-headers | wc -l | awk '{print "  " $$1 " instance(s)"}' 2>/dev/null || echo "  Non installé"

clean: ## 🧹 Supprimer l'application ArgoCD (garde les opérateurs)
	@echo "🧹 Suppression de l'application ArgoCD..."
	@oc delete application openshift-ai-main -n openshift-gitops 2>/dev/null || echo "Application déjà supprimée"
	@echo "✅ Application supprimée. Les opérateurs restent installés."