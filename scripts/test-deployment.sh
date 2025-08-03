#!/bin/bash
# Tests complets OpenShift AI 2.22

echo "🧪 Tests OpenShift AI 2.22 - Déploiement GitOps"
echo "================================================="

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TOTAL_TESTS=0
PASSED_TESTS=0

test_result() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
    fi
}

echo "🔍 Test 1: Connexion au cluster"
oc cluster-info >/dev/null 2>&1
test_result $? "Connexion au cluster OpenShift"

echo ""
echo "🔍 Test 2: Applications ArgoCD"
oc get application openshift-ai-main -n openshift-gitops >/dev/null 2>&1
test_result $? "Application ArgoCD existe"

APP_SYNC=$(oc get application openshift-ai-main -n openshift-gitops -o jsonpath='{.status.sync.status}' 2>/dev/null)
[ "$APP_SYNC" = "Synced" ]
test_result $? "Application ArgoCD synchronisée ($APP_SYNC)"

APP_HEALTH=$(oc get application openshift-ai-main -n openshift-gitops -o jsonpath='{.status.health.status}' 2>/dev/null)
[ "$APP_HEALTH" = "Healthy" ]
test_result $? "Application ArgoCD en bonne santé ($APP_HEALTH)"

echo ""
echo "🔍 Test 3: Opérateurs installés"
# GitOps
oc get csv -n openshift-operators | grep gitops | grep -q Succeeded
test_result $? "OpenShift GitOps opérateur"

# Service Mesh
oc get csv -n openshift-operators | grep servicemesh | grep -q Succeeded
test_result $? "Service Mesh opérateur"

# Serverless
oc get csv -n openshift-operators | grep serverless | grep -q Succeeded
test_result $? "Serverless opérateur"

# Pipelines
oc get csv -n openshift-operators | grep pipelines | grep -q Succeeded
test_result $? "Pipelines opérateur"

# Kueue
oc get csv -n openshift-operators | grep kueue | grep -q Succeeded
test_result $? "Kueue opérateur"

# RHOAI
oc get csv -n openshift-operators | grep rhods | grep -q Succeeded
test_result $? "Red Hat OpenShift AI opérateur"

echo ""
echo "🔍 Test 4: Instances des services"
# DataScienceCluster
oc get dsc >/dev/null 2>&1
test_result $? "DataScienceCluster existe"

if oc get dsc >/dev/null 2>&1; then
    DSC_STATUS=$(oc get dsc -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
    [ "$DSC_STATUS" = "Ready" ]
    test_result $? "DataScienceCluster prêt ($DSC_STATUS)"
fi

# Service Mesh Control Plane
oc get smcp -n istio-system >/dev/null 2>&1
test_result $? "Service Mesh Control Plane"

# Knative Serving
oc get knativeserving -n knative-serving >/dev/null 2>&1
test_result $? "Knative Serving"

echo ""
echo "🔍 Test 5: Pods et services"
# Pods RHOAI
RHOAI_PODS=$(oc get pods -n redhat-ods-applications --no-headers 2>/dev/null | grep Running | wc -l)
[ $RHOAI_PODS -gt 0 ]
test_result $? "Pods OpenShift AI actifs ($RHOAI_PODS)"

# Dashboard route
oc get route rhods-dashboard -n redhat-ods-applications >/dev/null 2>&1
test_result $? "Route Dashboard OpenShift AI"

echo ""
echo "🔍 Test 6: URLs d'accès"
# ArgoCD URL
ARGOCD_URL=$(oc get route argocd-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null)
[ -n "$ARGOCD_URL" ]
test_result $? "URL ArgoCD disponible"

# OpenShift AI URL
RHOAI_URL=$(oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}' 2>/dev/null)
[ -n "$RHOAI_URL" ]
test_result $? "URL OpenShift AI disponible"

echo ""
echo "================================================="
echo "📊 RÉSULTATS DES TESTS"
echo "================================================="
echo -e "Total: $TOTAL_TESTS tests"
echo -e "${GREEN}Réussis: $PASSED_TESTS${NC}"
echo -e "${RED}Échoués: $((TOTAL_TESTS - PASSED_TESTS))${NC}"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "\n🎉 ${GREEN}TOUS LES TESTS RÉUSSIS !${NC}"
    echo ""
    echo "🌐 Accès aux interfaces:"
    echo "  ArgoCD: https://$ARGOCD_URL"
    echo "  OpenShift AI: https://$RHOAI_URL"
    echo ""
    echo "🔐 Connexion ArgoCD:"
    echo "  User: admin"
    echo "  Password: \$(oc get secret argocd-initial-admin-secret -n openshift-gitops -o jsonpath='{.data.password}' | base64 -d)"
    exit 0
else
    echo -e "\n⚠️  ${YELLOW}CERTAINS TESTS ONT ÉCHOUÉ${NC}"
    echo "Vérifiez les logs et l'état des composants."
    exit 1
fi
