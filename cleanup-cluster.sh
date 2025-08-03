#!/bin/bash
# Script de nettoyage complet OpenShift pour installation GitOps propre
# Usage: ./cleanup-cluster.sh

set -e

echo "🧹 NETTOYAGE COMPLET CLUSTER OPENSHIFT"
echo "======================================"
echo ""
echo "⚠️  ATTENTION: Ce script va supprimer TOUS LES OPÉRATEURS:"
echo "   - OpenShift AI (RHOAI) complet + opérateur"
echo "   - Service Mesh complet + opérateurs (Istio, Kiali, Jaeger)"
echo "   - Serverless complet + opérateur"
echo "   - Pipelines complet + opérateur"
echo "   - Authorino opérateur"
echo "   - Minio et stockage S3"
echo ""
echo "🔥 SUPPRESSION TOTALE - PLUS D'OPÉRATEURS RESTANTS"
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
echo "📋 Étape 1/10: Suppression instances OpenShift AI"
oc delete dsc --all --timeout=60s --ignore-not-found || true
oc delete dsci --all --timeout=60s --ignore-not-found || true
wait_for_deletion "dsc"

# 2. Supprimer les namespaces OpenShift AI AVANT l'opérateur
echo ""
echo "📋 Étape 2/10: Suppression namespaces RHOAI"
oc delete namespace redhat-ods-applications --timeout=120s --ignore-not-found || true
oc delete namespace redhat-ods-monitoring --timeout=120s --ignore-not-found || true  
oc delete namespace redhat-ods-operator --timeout=120s --ignore-not-found || true

# 3. Supprimer l'opérateur RHOAI
echo ""
echo "📋 Étape 3/10: Suppression opérateur RHOAI"
oc delete subscription rhods-operator -n openshift-operators --ignore-not-found || true
oc delete csv -n openshift-operators -l operators.coreos.com/rhods-operator.openshift-operators --ignore-not-found || true

# 4. Supprimer Service Mesh instances et namespace
echo ""
echo "📋 Étape 4/10: Suppression instances Service Mesh"
oc delete smcp --all -n istio-system --timeout=60s --ignore-not-found || true
oc delete smmr --all -n istio-system --timeout=60s --ignore-not-found || true
oc delete namespace istio-system --timeout=120s --ignore-not-found || true

# 5. Supprimer opérateurs Service Mesh
echo ""
echo "📋 Étape 5/10: Suppression opérateurs Service Mesh"
oc delete subscription servicemeshoperator -n openshift-operators --ignore-not-found || true
oc delete subscription kiali-ossm -n openshift-operators --ignore-not-found || true  
oc delete subscription jaeger-product -n openshift-operators --ignore-not-found || true
oc delete csv -n openshift-operators -l operators.coreos.com/servicemeshoperator.openshift-operators --ignore-not-found || true
oc delete csv -n openshift-operators -l operators.coreos.com/kiali-ossm.openshift-operators --ignore-not-found || true
oc delete csv -n openshift-operators -l operators.coreos.com/jaeger-product.openshift-operators --ignore-not-found || true

# 6. Supprimer Serverless instances et namespace
echo ""
echo "📋 Étape 6/10: Suppression instances Serverless"
oc delete knativeserving --all -n knative-serving --timeout=60s --ignore-not-found || true
oc delete knativeeventing --all -n knative-eventing --timeout=60s --ignore-not-found || true
oc delete namespace knative-serving --timeout=120s --ignore-not-found || true
oc delete namespace knative-eventing --timeout=120s --ignore-not-found || true

# 7. Supprimer opérateur Serverless
echo ""
echo "📋 Étape 7/10: Suppression opérateur Serverless"
oc delete subscription serverless-operator -n openshift-operators --ignore-not-found || true
oc delete csv -n openshift-operators -l operators.coreos.com/serverless-operator.openshift-operators --ignore-not-found || true

# 8. Supprimer Pipelines et namespace
echo ""
echo "📋 Étape 8/10: Suppression Pipelines"
oc delete namespace openshift-pipelines --timeout=120s --ignore-not-found || true
oc delete subscription openshift-pipelines-operator-rh -n openshift-operators --ignore-not-found || true
oc delete csv -n openshift-operators -l operators.coreos.com/openshift-pipelines-operator-rh.openshift-operators --ignore-not-found || true

# 9. Supprimer Authorino
echo ""
echo "📋 Étape 9/10: Suppression Authorino"
oc delete subscription authorino-operator -n openshift-operators --ignore-not-found || true
oc delete csv -n openshift-operators -l operators.coreos.com/authorino-operator.openshift-operators --ignore-not-found || true

# 10. Supprimer Minio
echo ""
echo "📋 Étape 10/11: Suppression Minio"
oc delete namespace minio --timeout=120s --ignore-not-found || true
oc delete pv --selector=app=minio --ignore-not-found || true

# 11. Nettoyer les webhooks cassés
echo ""
echo "📋 Étape 11/11: Nettoyage webhooks cassés"
oc delete validatingwebhookconfigurations -l app.kubernetes.io/part-of=tekton-operator --ignore-not-found || true
oc delete mutatingwebhookconfigurations -l app.kubernetes.io/part-of=tekton-operator --ignore-not-found || true
oc delete validatingwebhookconfigurations namespace.operator.tekton.dev --ignore-not-found || true
oc delete validatingwebhookconfigurations config.webhook.istio.io --ignore-not-found || true
oc delete mutatingwebhookconfigurations istio-sidecar-injector --ignore-not-found || true

# Nettoyer aussi les webhooks GitOps au cas où
oc delete validatingwebhookconfigurations -l app.kubernetes.io/part-of=argocd --ignore-not-found || true
oc delete mutatingwebhookconfigurations -l app.kubernetes.io/part-of=argocd --ignore-not-found || true

# 12. Attendre et vérifier
echo ""
echo "📋 Vérification finale..."
sleep 30

echo ""
echo "✅ NETTOYAGE COMPLET TERMINÉ"
echo "==========================="
echo ""
echo "🔍 Vérification:"

# Vérifier OpenShift AI
if oc get dsc,dsci >/dev/null 2>&1; then
    echo "❌ OpenShift AI encore présent"
    oc get dsc,dsci
else
    echo "✅ OpenShift AI supprimé"
fi

# Vérifier les opérateurs
echo ""
echo "🔍 Opérateurs restants dans openshift-operators:"
OPERATORS=$(oc get subscription -n openshift-operators | grep -E "(rhods|servicemesh|serverless|pipelines|authorino)" || true)
if [ -n "$OPERATORS" ]; then
    echo "$OPERATORS"
    echo "❌ Certains opérateurs existent encore"
else
    echo "✅ Tous les opérateurs ciblés supprimés"
fi

# Vérifier les namespaces
echo ""
echo "🔍 Namespaces restants:"
REMAINING_NS=$(oc get namespaces | grep -E "(ods|minio|istio|knative|pipelines)" || true)
if [ -n "$REMAINING_NS" ]; then
    echo "$REMAINING_NS"
    echo "⚠️ Certains namespaces existent encore"
else
    echo "✅ Tous les namespaces ciblés supprimés"
fi

echo ""
echo "🎯 CLUSTER TOTALEMENT PROPRE pour installation GitOps !"
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
