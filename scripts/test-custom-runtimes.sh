#!/bin/bash
# Test des custom serving runtimes Triton et Seldon
# Vérification post-déploiement GitOps

echo "🧪 Test des Custom Serving Runtimes OpenShift AI 2.22"
echo "====================================================="

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo "🔍 Test 1: Application ArgoCD synchronisée"
APP_SYNC=$(oc get applications.argoproj.io openshift-ai-complete -n openshift-gitops -o jsonpath='{.status.sync.status}' 2>/dev/null)
[ "$APP_SYNC" = "Synced" ]
test_result $? "Application ArgoCD synchronisée ($APP_SYNC)"

echo ""
echo "🔍 Test 2: Templates installés"

# Test Template NVIDIA Triton
oc get template nvidia-triton-runtime-template -n redhat-ods-applications >/dev/null 2>&1
test_result $? "Template NVIDIA Triton présent"

# Test Template Seldon MLServer
oc get template seldon-mlserver-template -n redhat-ods-applications >/dev/null 2>&1
test_result $? "Template Seldon MLServer présent"

echo ""
echo "🔍 Test 3: Serving Runtimes installés"

# Test NVIDIA Triton Runtime
oc get servingruntime triton-runtime -n redhat-ods-applications >/dev/null 2>&1
test_result $? "NVIDIA Triton Runtime présent"

# Test Seldon MLServer Runtime  
oc get servingruntime seldon-mlserver-runtime -n redhat-ods-applications >/dev/null 2>&1
test_result $? "Seldon MLServer Runtime présent"

echo ""
echo "🔍 Test 4: Configuration des runtimes"

# Vérifier les formats supportés par Triton
TRITON_FORMATS=$(oc get servingruntime triton-runtime -n redhat-ods-applications -o jsonpath='{.spec.supportedModelFormats[*].name}' 2>/dev/null)
echo "$TRITON_FORMATS" | grep -q "tensorflow" && echo "$TRITON_FORMATS" | grep -q "pytorch" && echo "$TRITON_FORMATS" | grep -q "onnx"
test_result $? "Triton supporte TensorFlow, PyTorch, ONNX ($TRITON_FORMATS)"

# Vérifier les formats supportés par Seldon
SELDON_FORMATS=$(oc get servingruntime seldon-mlserver-runtime -n redhat-ods-applications -o jsonpath='{.spec.supportedModelFormats[*].name}' 2>/dev/null)
echo "$SELDON_FORMATS" | grep -q "sklearn" && echo "$SELDON_FORMATS" | grep -q "xgboost" && echo "$SELDON_FORMATS" | grep -q "mlflow"
test_result $? "Seldon supporte sklearn, XGBoost, MLflow ($SELDON_FORMATS)"

echo ""
echo "🔍 Test 5: Configuration Prometheus"

# Vérifier les annotations Prometheus Triton
TRITON_PROMETHEUS=$(oc get servingruntime triton-runtime -n redhat-ods-applications -o jsonpath='{.spec.annotations}' 2>/dev/null)
echo "$TRITON_PROMETHEUS" | grep -q "prometheus.kserve.io"
test_result $? "Triton - Annotations Prometheus configurées"

# Vérifier les annotations Prometheus Seldon
SELDON_PROMETHEUS=$(oc get servingruntime seldon-mlserver-runtime -n redhat-ods-applications -o jsonpath='{.spec.annotations}' 2>/dev/null)
echo "$SELDON_PROMETHEUS" | grep -q "prometheus.kserve.io"
test_result $? "Seldon - Annotations Prometheus configurées"

echo ""
echo "🔍 Test 6: Configuration multi-model"

# Vérifier multi-model pour Triton
TRITON_MULTIMODEL=$(oc get servingruntime triton-runtime -n redhat-ods-applications -o jsonpath='{.spec.multiModel}' 2>/dev/null)
[ "$TRITON_MULTIMODEL" = "true" ]
test_result $? "Triton - Multi-model supporté ($TRITON_MULTIMODEL)"

# Vérifier multi-model pour Seldon  
SELDON_MULTIMODEL=$(oc get servingruntime seldon-mlserver-runtime -n redhat-ods-applications -o jsonpath='{.spec.multiModel}' 2>/dev/null)
[ "$SELDON_MULTIMODEL" = "true" ]
test_result $? "Seldon - Multi-model supporté ($SELDON_MULTIMODEL)"

echo ""
echo "🔍 Test 8: Configuration pour l'interface dashboard"

# Vérifier les annotations d'affichage Triton
TRITON_DASHBOARD=$(oc get servingruntime triton-runtime -n redhat-ods-applications -o jsonpath='{.metadata.labels.opendatahub\.io/dashboard}' 2>/dev/null)
[ "$TRITON_DASHBOARD" = "true" ]
test_result $? "Triton - Label dashboard configuré ($TRITON_DASHBOARD)"

TRITON_DISPLAY=$(oc get servingruntime triton-runtime -n redhat-ods-applications -o jsonpath='{.metadata.annotations.openshift\.io/display-name}' 2>/dev/null)
[ "$TRITON_DISPLAY" = "NVIDIA Triton Inference Server" ]
test_result $? "Triton - Nom d'affichage configuré ($TRITON_DISPLAY)"

# Vérifier les annotations d'affichage Seldon
SELDON_DASHBOARD=$(oc get servingruntime seldon-mlserver-runtime -n redhat-ods-applications -o jsonpath='{.metadata.labels.opendatahub\.io/dashboard}' 2>/dev/null)
[ "$SELDON_DASHBOARD" = "true" ]
test_result $? "Seldon - Label dashboard configuré ($SELDON_DASHBOARD)"

SELDON_DISPLAY=$(oc get servingruntime seldon-mlserver-runtime -n redhat-ods-applications -o jsonpath='{.metadata.annotations.openshift\.io/display-name}' 2>/dev/null)
[ "$SELDON_DISPLAY" = "Seldon MLServer" ]
test_result $? "Seldon - Nom d'affichage configuré ($SELDON_DISPLAY)"

echo ""
echo "🔍 Test 7: Vérification des images"

# Vérifier l'image Triton
TRITON_IMAGE=$(oc get servingruntime triton-runtime -n redhat-ods-applications -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
echo "$TRITON_IMAGE" | grep -q "nvcr.io/nvidia/tritonserver"
test_result $? "Triton - Image officielle NVIDIA ($TRITON_IMAGE)"

# Vérifier l'image Seldon
SELDON_IMAGE=$(oc get servingruntime seldon-mlserver-runtime -n redhat-ods-applications -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
echo "$SELDON_IMAGE" | grep -q "seldonio/mlserver"
test_result $? "Seldon - Image officielle Seldon ($SELDON_IMAGE)"

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
    echo -e "${BLUE}📋 Runtimes disponibles :${NC}"
    echo "  • NVIDIA Triton (TensorFlow, PyTorch, ONNX, TensorRT)"
    echo "  • Seldon MLServer (scikit-learn, XGBoost, MLflow, Hugging Face)"
    echo ""
    echo -e "${BLUE}🚀 Utilisation :${NC}"
    echo "  1. OpenShift AI Dashboard → Model Serving"
    echo "  2. Deploy model → Sélectionner runtime approprié"
    echo "  3. Configurer modèle selon format supporté"
    echo ""
    echo -e "${BLUE}📊 Monitoring :${NC}"
    echo "  • Triton metrics: http://<service>:8002/metrics"
    echo "  • Seldon metrics: http://<service>:8080/metrics"
    exit 0
else
    echo -e "\n⚠️  ${YELLOW}CERTAINS TESTS ONT ÉCHOUÉ${NC}"
    echo "Vérifiez la synchronisation ArgoCD et les logs des pods."
    exit 1
fi
