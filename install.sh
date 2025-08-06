#!/bin/bash
# Installation complète OpenShift AI 2.22 via GitOps

set -e

echo "🚀 OpenShift AI 2.22 - Déploiement GitOps"
echo "=========================================="

# Vérifier les prérequis
if ! command -v oc &> /dev/null; then
    echo "❌ CLI 'oc' non trouvé. Installez OpenShift CLI."
    exit 1
fi

if ! oc whoami &> /dev/null; then
    echo "❌ Non connecté à OpenShift. Utilisez 'oc login'."
    exit 1
fi

echo "✅ Prérequis validés"

# 1. Installer GitOps si pas déjà présent
if ! oc get csv -n openshift-operators | grep -q "gitops.*Succeeded"; then
    echo "📦 Installation OpenShift GitOps..."
    ./scripts/install-gitops.sh
else
    echo "✅ GitOps déjà installé"
fi

# 2. Déployer OpenShift AI via ArgoCD
echo "🎯 Déploiement OpenShift AI via ArgoCD..."
oc apply -f argocd-apps/openshift-ai-application.yaml

echo "⏳ Attente synchronisation ArgoCD..."
sleep 30

# 3. Vérifier le déploiement
echo "🔍 Vérification du déploiement..."
for i in {1..10}; do
    SYNC_STATUS=$(oc get applications.argoproj.io openshift-ai-complete -n openshift-gitops -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    HEALTH_STATUS=$(oc get applications.argoproj.io openshift-ai-complete -n openshift-gitops -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    
    echo "  Sync: $SYNC_STATUS | Health: $HEALTH_STATUS"
    
    if [[ "$SYNC_STATUS" == "Synced" && "$HEALTH_STATUS" == "Healthy" ]]; then
        echo "✅ Déploiement réussi !"
        break
    fi
    
    if [ $i -eq 10 ]; then
        echo "⚠️  Sync en cours... Vérifiez avec: oc get applications.argoproj.io -n openshift-gitops"
        # Correction SSL immédiate si Model Registry disponible
        if oc get modelregistry default-model-registry -n rhoai-model-registries >/dev/null 2>&1; then
            echo "🔧 Application correction SSL pour Model Registry..."
            oc annotate route rhods-dashboard -n redhat-ods-applications haproxy.router.openshift.io/backend-protocol=http --overwrite >/dev/null 2>&1 || true
            oc rollout restart deployment rhods-dashboard -n redhat-ods-applications >/dev/null 2>&1 || true
            echo "✅ Correction SSL appliquée"
        fi
    fi
    
    sleep 30
done

# 4. Afficher les informations de connexion
echo ""
echo "🌐 Accès aux services:"
echo "----------------------"

ARGOCD_URL=$(oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null || echo "Non disponible")
RHOAI_URL=$(oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}' 2>/dev/null || echo "En cours de déploiement")

echo "ArgoCD  : https://$ARGOCD_URL"
echo "RHOAI   : https://$RHOAI_URL"

echo ""
echo "🎉 Installation terminée !"
echo "   Surveillez la sync ArgoCD pour le statut complet."
