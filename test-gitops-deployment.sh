#!/bin/bash
# Script de test et validation du déploiement GitOps OpenShift AI
# Usage: ./test-gitops-deployment.sh

set -e

echo "🧪 TEST DÉPLOIEMENT GITOPS OPENSHIFT AI"
echo "======================================="
echo ""

# Fonction d'attente avec timeout
wait_for_condition() {
    local condition="$1"
    local description="$2"
    local timeout=300
    local elapsed=0
    
    echo "⏳ Attente: $description..."
    while [ $elapsed -lt $timeout ]; do
        if eval "$condition" >/dev/null 2>&1; then
            echo "✅ $description - OK"
            return 0
        fi
        sleep 10
        elapsed=$((elapsed + 10))
        echo "   ... $elapsed/${timeout}s"
    done
    echo "❌ Timeout: $description"
    return 1
}

# Test 1: Vérifier OpenShift GitOps
echo "📋 Test 1/7: OpenShift GitOps"
if oc get subscription openshift-gitops-operator -n openshift-operators >/dev/null 2>&1; then
    echo "✅ Opérateur GitOps installé"
    
    # Attendre que ArgoCD soit prêt
    wait_for_condition "oc get deployment argocd-server -n openshift-gitops | grep -q '1/1'" "ArgoCD Server ready"
    
    # Obtenir l'URL ArgoCD
    ARGOCD_URL=$(oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null || echo "URL non disponible")
    echo "🌐 ArgoCD URL: https://$ARGOCD_URL"
    
    # Obtenir le mot de passe admin
    ARGOCD_PASSWORD=$(oc get secret argocd-initial-admin-secret -n openshift-gitops -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo "Password non disponible")
    echo "🔑 Admin password: $ARGOCD_PASSWORD"
else
    echo "❌ Opérateur GitOps non installé"
    echo "   Installer avec: oc apply -f components/operators/openshift-gitops-operator/base/subscription.yaml"
    exit 1
fi

# Test 2: Vérifier l'Application ArgoCD
echo ""
echo "📋 Test 2/7: Application ArgoCD"
if oc get application openshift-ai-setup -n openshift-gitops >/dev/null 2>&1; then
    echo "✅ Application ArgoCD trouvée"
    
    # Vérifier le statut de sync
    SYNC_STATUS=$(oc get application openshift-ai-setup -n openshift-gitops -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    HEALTH_STATUS=$(oc get application openshift-ai-setup -n openshift-gitops -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    
    echo "🔄 Sync Status: $SYNC_STATUS"
    echo "💚 Health Status: $HEALTH_STATUS"
    
    if [ "$SYNC_STATUS" = "Synced" ]; then
        echo "✅ Application synchronisée"
    else
        echo "⚠️ Application pas encore synchronisée"
        echo "   Forcer sync: oc patch application openshift-ai-setup -n openshift-gitops --type merge -p '{\"operation\":{\"initiatedBy\":{\"username\":\"admin\"},\"sync\":{\"revision\":\"main\"}}}'"
    fi
else
    echo "❌ Application ArgoCD non trouvée"
    echo "   Installer avec: oc apply -f argocd/openshift-ai-application-public.yaml"
    exit 1
fi

# Test 3: Vérifier OpenShift AI
echo ""
echo "📋 Test 3/7: OpenShift AI Core"
wait_for_condition "oc get subscription rhods-operator -n openshift-operators" "Subscription RHOAI"

if oc get dsci,dsc >/dev/null 2>&1; then
    echo "✅ OpenShift AI installé"
    
    # Vérifier DSCI
    DSCI_PHASE=$(oc get dsci -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Unknown")
    echo "🎯 DSCI Phase: $DSCI_PHASE"
    
    # Vérifier DSC
    DSC_PHASE=$(oc get dsc -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Unknown")
    echo "🎯 DSC Phase: $DSC_PHASE"
    
    if [ "$DSC_PHASE" = "Ready" ]; then
        echo "✅ OpenShift AI Ready"
    else
        echo "⏳ OpenShift AI en cours d'installation..."
    fi
else
    echo "❌ OpenShift AI non installé"
fi

# Test 4: Vérifier les namespaces
echo ""
echo "📋 Test 4/7: Namespaces OpenShift AI"
EXPECTED_NS=("redhat-ods-applications" "redhat-ods-monitoring" "redhat-ods-operator")
for ns in "${EXPECTED_NS[@]}"; do
    if oc get namespace "$ns" >/dev/null 2>&1; then
        echo "✅ Namespace $ns"
    else
        echo "❌ Namespace $ns manquant"
    fi
done

# Test 5: Vérifier Minio
echo ""
echo "📋 Test 5/7: Minio S3 Storage"
if oc get namespace minio >/dev/null 2>&1; then
    echo "✅ Namespace Minio"
    
    # Vérifier les pods Minio
    MINIO_PODS=$(oc get pods -n minio --no-headers 2>/dev/null | wc -l || echo "0")
    echo "📦 Minio pods: $MINIO_PODS"
    
    if [ "$MINIO_PODS" -gt 0 ]; then
        # Vérifier l'URL Minio
        MINIO_URL=$(oc get route minio-ui -n minio -o jsonpath='{.spec.host}' 2>/dev/null || echo "URL non disponible")
        echo "🌐 Minio URL: https://$MINIO_URL"
    fi
else
    echo "❌ Namespace Minio manquant"
fi

# Test 6: Vérifier Model Registry
echo ""
echo "📋 Test 6/7: Model Registry"
if oc get pods -n model-registry >/dev/null 2>&1; then
    REGISTRY_PODS=$(oc get pods -n model-registry --no-headers 2>/dev/null | wc -l || echo "0")
    echo "✅ Model Registry pods: $REGISTRY_PODS"
else
    echo "⚠️ Model Registry pas encore déployé"
fi

# Test 7: Vérifier les routes principales
echo ""
echo "📋 Test 7/7: Routes et accès"
echo "🌐 URLs principales:"

# RHOAI Dashboard
RHOAI_URL=$(oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}' 2>/dev/null || echo "En cours...")
echo "   OpenShift AI: https://$RHOAI_URL"

# ArgoCD
echo "   ArgoCD: https://$ARGOCD_URL"

# Minio
if [ "$MINIO_URL" != "URL non disponible" ]; then
    echo "   Minio: https://$MINIO_URL"
fi

# Test de connectivité
echo ""
echo "🔗 Test de connectivité:"
if command -v curl >/dev/null 2>&1; then
    if [ "$RHOAI_URL" != "En cours..." ]; then
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$RHOAI_URL" || echo "000")
        if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "302" ] || [ "$HTTP_STATUS" = "301" ]; then
            echo "✅ OpenShift AI accessible (HTTP $HTTP_STATUS)"
        else
            echo "⚠️ OpenShift AI pas encore accessible (HTTP $HTTP_STATUS)"
        fi
    fi
else
    echo "⚠️ curl non disponible pour test connectivité"
fi

# Résumé final
echo ""
echo "📊 RÉSUMÉ DU DÉPLOIEMENT"
echo "======================="
echo "GitOps Operator: ✅"
echo "ArgoCD Application: $([ "$SYNC_STATUS" = "Synced" ] && echo "✅" || echo "⏳")"
echo "OpenShift AI: $([ "$DSC_PHASE" = "Ready" ] && echo "✅" || echo "⏳")"
echo "Minio Storage: $([ "$MINIO_PODS" -gt 0 ] && echo "✅" || echo "⏳")"

echo ""
echo "🎯 PROCHAINES ÉTAPES:"
if [ "$DSC_PHASE" = "Ready" ]; then
    echo "✅ Déploiement terminé ! Accédez à OpenShift AI:"
    echo "   https://$RHOAI_URL"
else
    echo "⏳ Déploiement en cours... Réexécuter ce script dans 5-10 minutes"
    echo "   ou surveiller dans ArgoCD: https://$ARGOCD_URL"
fi

echo ""
echo "📚 Documentation:"
echo "   - Guide: INSTALL-PUBLIC-REPO.md"
echo "   - ArgoCD UI: admin / $ARGOCD_PASSWORD"
