#!/bin/bash
# Script de nettoyage complet OpenShift pour installation GitOps propre
# Usage: ./cleanup-cluster.sh

set -e

echo "🧹 NETTOYAGE COMPLET CLUSTER OPENSHIFT"
echo "======================================"
echo ""
echo "⚠️  ATTENTION: Ce script va supprimer:"
echo "   - OpenShift AI (RHOAI) complet"
echo "   - Minio et stockage S3"
echo "   - Service Mesh (optionnel)"
echo "   - Serverless (optionnel)"
echo "   - Pipelines (optionnel)"
echo ""

read -p "Êtes-vous sûr de vouloir continuer ? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Nettoyage annulé."
    exit 0
fi

echo ""
echo "🚀 Début du nettoyage..."

# Fonction pour attendre la suppression
wait_for_deletion() {
    local resource=$1
    local namespace=${2:-""}
    local timeout=120
    local elapsed=0
    
    echo "⏳ Attente suppression $resource..."
    while [ $elapsed -lt $timeout ]; do
        if [ -n "$namespace" ]; then
            if ! oc get $resource -n $namespace >/dev/null 2>&1; then
                echo "✅ $resource supprimé"
                return 0
            fi
        else
            if ! oc get $resource >/dev/null 2>&1; then
                echo "✅ $resource supprimé"
                return 0
            fi
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done
    echo "⚠️ Timeout pour $resource"
}

# 1. Supprimer OpenShift AI
echo ""
echo "📋 Étape 1/6: Suppression OpenShift AI"
oc delete dsc --all --timeout=60s --ignore-not-found || true
oc delete dsci --all --timeout=60s --ignore-not-found || true
wait_for_deletion "dsc"

# 2. Supprimer l'opérateur RHOAI
echo ""
echo "📋 Étape 2/6: Suppression opérateur RHOAI"
oc delete subscription rhods-operator -n openshift-operators --ignore-not-found || true
oc delete csv -n openshift-operators -l operators.coreos.com/rhods-operator.openshift-operators --ignore-not-found || true

# 3. Supprimer les namespaces OpenShift AI
echo ""
echo "📋 Étape 3/6: Suppression namespaces RHOAI"
oc delete namespace redhat-ods-applications --timeout=120s --ignore-not-found || true
oc delete namespace redhat-ods-monitoring --timeout=120s --ignore-not-found || true  
oc delete namespace redhat-ods-operator --timeout=120s --ignore-not-found || true

# 4. Supprimer Minio
echo ""
echo "📋 Étape 4/6: Suppression Minio"
oc delete namespace minio --timeout=120s --ignore-not-found || true
oc delete pv --selector=app=minio --ignore-not-found || true

# 5. Supprimer Service Mesh (optionnel)
echo ""
read -p "Supprimer Service Mesh ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📋 Étape 5/6: Suppression Service Mesh"
    oc delete smcp --all -n istio-system --timeout=60s --ignore-not-found || true
    oc delete smmr --all -n istio-system --timeout=60s --ignore-not-found || true
    oc delete namespace istio-system --timeout=120s --ignore-not-found || true
else
    echo "📋 Étape 5/6: Service Mesh conservé"
fi

# 6. Supprimer Serverless et Pipelines (optionnel)
echo ""
read -p "Supprimer Serverless et Pipelines ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📋 Étape 6/6: Suppression Serverless et Pipelines"
    oc delete knativeserving --all -n knative-serving --timeout=60s --ignore-not-found || true
    oc delete namespace knative-serving --timeout=120s --ignore-not-found || true
    oc delete namespace openshift-pipelines --timeout=120s --ignore-not-found || true
else
    echo "📋 Étape 6/6: Serverless et Pipelines conservés"
fi

# 7. Attendre et vérifier
echo ""
echo "📋 Vérification finale..."
sleep 30

echo ""
echo "✅ NETTOYAGE TERMINÉ"
echo "==================="
echo ""
echo "🔍 Vérification:"

# Vérifier OpenShift AI
if oc get dsc,dsci >/dev/null 2>&1; then
    echo "❌ OpenShift AI encore présent"
    oc get dsc,dsci
else
    echo "✅ OpenShift AI supprimé"
fi

# Vérifier les namespaces
echo ""
echo "🔍 Namespaces restants:"
REMAINING_NS=$(oc get namespaces | grep -E "(ods|minio|istio|knative)" || true)
if [ -n "$REMAINING_NS" ]; then
    echo "$REMAINING_NS"
    echo "⚠️ Certains namespaces existent encore"
else
    echo "✅ Tous les namespaces ciblés supprimés"
fi

echo ""
echo "🎯 CLUSTER PRÊT pour installation GitOps !"
echo ""
echo "📝 Prochaines étapes (REPO PUBLIC - plus simple!):"
echo "1. git clone https://github.com/mouachan/openshift-ai-setup.git"
echo "2. oc apply -f components/operators/openshift-gitops-operator/base/subscription.yaml"  
echo "3. oc apply -f argocd/openshift-ai-application-public.yaml"
echo ""
echo "🌐 Avantages repo public:"
echo "   ✅ Pas de configuration SSH nécessaire"
echo "   ✅ ArgoCD accès direct HTTPS"
echo "   ✅ Déploiement immédiat"
