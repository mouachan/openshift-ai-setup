#!/bin/bash
# Script de diagnostic GitOps + OpenShift AI
# Usage: ./diagnostics-gitops.sh

set -e

echo "🔍 DIAGNOSTIC GITOPS + OPENSHIFT AI"
echo "=================================="
echo ""

# 1. Vérifier l'état de GitOps
echo "📋 1. État de GitOps"
echo "-------------------"

if oc get sub openshift-gitops-operator -n openshift-operators >/dev/null 2>&1; then
    echo "✅ GitOps Operator installé"
    GITOPS_STATUS=$(oc get csv -n openshift-operators -l operators.coreos.com/openshift-gitops-operator.openshift-operators -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")
    echo "   Status: $GITOPS_STATUS"
else
    echo "❌ GitOps Operator non installé"
    exit 1
fi

# 2. Vérifier ArgoCD
echo ""
echo "📋 2. État d'ArgoCD"
echo "------------------"

if oc get deployment openshift-gitops-server -n openshift-gitops >/dev/null 2>&1; then
    ARGOCD_READY=$(oc get deployment openshift-gitops-server -n openshift-gitops -o jsonpath='{.status.readyReplicas}')
    ARGOCD_DESIRED=$(oc get deployment openshift-gitops-server -n openshift-gitops -o jsonpath='{.status.replicas}')
    echo "✅ ArgoCD Server déployé ($ARGOCD_READY/$ARGOCD_DESIRED ready)"
else
    echo "❌ ArgoCD Server non trouvé"
    exit 1
fi

# 3. Vérifier l'application
echo ""
echo "📋 3. État de l'application OpenShift AI"
echo "---------------------------------------"

if oc get application openshift-ai-simple -n openshift-gitops >/dev/null 2>&1; then
    echo "✅ Application openshift-ai-simple trouvée"
    
    SYNC_STATUS=$(oc get application openshift-ai-simple -n openshift-gitops -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    HEALTH_STATUS=$(oc get application openshift-ai-simple -n openshift-gitops -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    
    echo "   Sync Status: $SYNC_STATUS"
    echo "   Health Status: $HEALTH_STATUS"
    
    # Afficher les conditions d'erreur
    echo ""
    echo "🔍 Conditions de l'application:"
    oc get application openshift-ai-simple -n openshift-gitops -o jsonpath='{.status.conditions}' | jq -r '.[] | "   - \(.type): \(.message)"' 2>/dev/null || echo "   Aucune condition disponible"
    
    # Afficher les ressources OutOfSync
    if [ "$SYNC_STATUS" = "OutOfSync" ]; then
        echo ""
        echo "⚠️  Ressources OutOfSync:"
        oc get application openshift-ai-simple -n openshift-gitops -o jsonpath='{.status.resources}' | jq -r '.[] | select(.status=="OutOfSync") | "   - \(.kind)/\(.name) in \(.namespace // "cluster")"' 2>/dev/null || echo "   Impossible de récupérer les détails"
    fi
    
else
    echo "❌ Application openshift-ai-simple non trouvée"
    exit 1
fi

# 4. Vérifier les opérateurs requis
echo ""
echo "📋 4. Opérateurs requis pour OpenShift AI"
echo "----------------------------------------"

# Liste des opérateurs critiques
OPERATORS=(
    "rhods-operator:redhat-ods-operator"
    "kueue:openshift-operators"
    "serverless-operator:openshift-serverless"
    "servicemeshoperator:openshift-operators"
)

for op_info in "${OPERATORS[@]}"; do
    IFS=':' read -r op_name op_namespace <<< "$op_info"
    if oc get csv -n "$op_namespace" | grep -q "$op_name" 2>/dev/null; then
        OP_STATUS=$(oc get csv -n "$op_namespace" | grep "$op_name" | awk '{print $NF}')
        echo "✅ $op_name: $OP_STATUS"
    else
        echo "❌ $op_name: Non installé"
    fi
done

# 5. Vérifier les namespaces
echo ""
echo "📋 5. Namespaces OpenShift AI"
echo "----------------------------"

NAMESPACES=(
    "redhat-ods-operator"
    "redhat-ods-applications"
    "redhat-ods-monitoring"
    "openshift-serverless"
    "istio-system"
    "knative-serving"
)

for ns in "${NAMESPACES[@]}"; do
    if oc get namespace "$ns" >/dev/null 2>&1; then
        echo "✅ $ns: Existe"
    else
        echo "❌ $ns: Manquant"
    fi
done

# 6. Rechercher les erreurs Kueue spécifiques
echo ""
echo "📋 6. Diagnostic Kueue spécifique"
echo "--------------------------------"

echo "🔍 Recherche de problèmes de version d'API Kueue..."
if oc get application openshift-ai-simple -n openshift-gitops -o yaml | grep -i "kueue" >/dev/null 2>&1; then
    echo "   Application contient des références Kueue"
    
    # Vérifier si l'API v1beta1 est disponible
    if oc api-resources --api-group=config.kueue.x-k8s.io | grep -q "v1beta1" 2>/dev/null; then
        echo "   ✅ API Kueue v1beta1 disponible"
    else
        echo "   ❌ API Kueue v1beta1 non disponible"
    fi
    
    # Vérifier les CRDs Kueue
    KUEUE_CRDS=$(oc get crd | grep kueue | wc -l || echo "0")
    echo "   CRDs Kueue trouvées: $KUEUE_CRDS"
    
else
    echo "   Aucune référence Kueue dans l'application"
fi

# 7. Suggestions de résolution
echo ""
echo "📋 7. Suggestions de résolution"
echo "------------------------------"

if [ "$SYNC_STATUS" = "OutOfSync" ]; then
    echo "💡 Pour résoudre les problèmes OutOfSync:"
    echo "   1. Forcer la synchronisation:"
    echo "      oc patch application openshift-ai-simple -n openshift-gitops --type merge -p '{\"operation\":{\"sync\":{}}}'"
    echo ""
    echo "   2. Supprimer et recréer l'application:"
    echo "      oc delete application openshift-ai-simple -n openshift-gitops"
    echo "      ./install-gitops.sh"
    echo ""
    echo "   3. Vérifier les logs ArgoCD:"
    echo "      oc logs deployment/openshift-gitops-application-controller -n openshift-gitops"
fi

if [ "$HEALTH_STATUS" = "Degraded" ] || [ "$HEALTH_STATUS" = "Unknown" ]; then
    echo "💡 Pour résoudre les problèmes de santé:"
    echo "   1. Vérifier les pods en erreur:"
    echo "      oc get pods --all-namespaces | grep -E '(Error|CrashLoopBackOff|ImagePullBackOff)'"
    echo ""
    echo "   2. Vérifier les événements:"
    echo "      oc get events --all-namespaces --sort-by='.lastTimestamp'"
fi

echo ""
echo "🎯 Diagnostic terminé!"
echo ""
echo "📞 Pour un support supplémentaire:"
echo "   - Vérifier la documentation: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.22/"
echo "   - Logs détaillés: oc logs deployment/openshift-gitops-application-controller -n openshift-gitops"
