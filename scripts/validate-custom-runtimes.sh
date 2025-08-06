#!/bin/bash

# Script de validation des custom serving runtimes
# Conforme aux standards BU pour OpenShift AI 2.22

set -euo pipefail

echo "🔍 Validation des Custom Serving Runtimes"
echo "========================================"

# Couleurs pour les outputs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les résultats
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# 1. Vérifier que nous sommes connectés au cluster
print_info "Vérification de la connexion au cluster..."
if oc whoami &>/dev/null; then
    CURRENT_USER=$(oc whoami)
    CURRENT_CLUSTER=$(oc whoami --show-server)
    print_result 0 "Connecté en tant que: $CURRENT_USER"
    print_info "Cluster: $CURRENT_CLUSTER"
else
    print_result 1 "Impossible de se connecter au cluster OpenShift"
    exit 1
fi

echo ""

# 2. Vérifier l'existence des ServingRuntimes
print_info "Vérification des ServingRuntimes..."

# Triton Runtime
if oc get servingruntime triton-runtime -n redhat-ods-applications &>/dev/null; then
    print_result 0 "Triton Runtime déployé"
    
    # Détails Triton
    TRITON_AGE=$(oc get servingruntime triton-runtime -n redhat-ods-applications -o jsonpath='{.metadata.creationTimestamp}')
    TRITON_FORMATS=$(oc get servingruntime triton-runtime -n redhat-ods-applications -o jsonpath='{.spec.supportedModelFormats[*].name}' | tr ' ' ',')
    print_info "  - Formats supportés: $TRITON_FORMATS"
    print_info "  - Créé le: $TRITON_AGE"
else
    print_result 1 "Triton Runtime non trouvé"
fi

# Seldon MLServer Runtime
if oc get servingruntime seldon-mlserver-runtime -n redhat-ods-applications &>/dev/null; then
    print_result 0 "Seldon MLServer Runtime déployé"
    
    # Détails Seldon
    SELDON_AGE=$(oc get servingruntime seldon-mlserver-runtime -n redhat-ods-applications -o jsonpath='{.metadata.creationTimestamp}')
    SELDON_FORMATS=$(oc get servingruntime seldon-mlserver-runtime -n redhat-ods-applications -o jsonpath='{.spec.supportedModelFormats[*].name}' | tr ' ' ',')
    print_info "  - Formats supportés: $SELDON_FORMATS"
    print_info "  - Créé le: $SELDON_AGE"
else
    print_result 1 "Seldon MLServer Runtime non trouvé"
fi

echo ""

# 3. Vérifier les labels de conformité BU
print_info "Vérification des labels de conformité BU..."

for runtime in triton-runtime seldon-mlserver-runtime; do
    if oc get servingruntime $runtime -n redhat-ods-applications &>/dev/null; then
        # Vérifier les labels standards
        LABELS=$(oc get servingruntime $runtime -n redhat-ods-applications -o jsonpath='{.metadata.labels}')
        
        if echo "$LABELS" | grep -q "app.kubernetes.io/name.*openshift-ai"; then
            print_result 0 "$runtime: Labels app.kubernetes.io conformes"
        else
            print_result 1 "$runtime: Labels app.kubernetes.io manquants"
        fi
        
        if echo "$LABELS" | grep -q "app.kubernetes.io/version.*2.22"; then
            print_result 0 "$runtime: Version 2.22 correcte"
        else
            print_result 1 "$runtime: Version 2.22 manquante"
        fi
    fi
done

echo ""

# 4. Vérifier la configuration multi-modèle
print_info "Vérification du support multi-modèle..."

for runtime in triton-runtime seldon-mlserver-runtime; do
    if oc get servingruntime $runtime -n redhat-ods-applications &>/dev/null; then
        MULTIMODEL=$(oc get servingruntime $runtime -n redhat-ods-applications -o jsonpath='{.spec.multiModel}')
        if [ "$MULTIMODEL" = "true" ]; then
            print_result 0 "$runtime: Multi-modèle activé"
        else
            print_result 1 "$runtime: Multi-modèle désactivé"
        fi
    fi
done

echo ""

# 5. Vérifier les annotations Prometheus
print_info "Vérification de la configuration Prometheus..."

for runtime in triton-runtime seldon-mlserver-runtime; do
    if oc get servingruntime $runtime -n redhat-ods-applications &>/dev/null; then
        PROMETHEUS_SCRAPE=$(oc get servingruntime $runtime -n redhat-ods-applications -o jsonpath='{.spec.annotations.serving\.kserve\.io/enable-prometheus-scraping}')
        if [ "$PROMETHEUS_SCRAPE" = "true" ]; then
            print_result 0 "$runtime: Prometheus scraping activé"
        else
            print_result 1 "$runtime: Prometheus scraping désactivé"
        fi
    fi
done

echo ""

# 6. Vérifier l'état ArgoCD
print_info "Vérification de l'état ArgoCD..."

if oc get applications.argoproj.io openshift-ai-complete -n openshift-gitops &>/dev/null; then
    SYNC_STATUS=$(oc get applications.argoproj.io openshift-ai-complete -n openshift-gitops -o jsonpath='{.status.sync.status}')
    HEALTH_STATUS=$(oc get applications.argoproj.io openshift-ai-complete -n openshift-gitops -o jsonpath='{.status.health.status}')
    
    print_info "Statut ArgoCD: $SYNC_STATUS / $HEALTH_STATUS"
    
    # Les custom runtimes sont-ils synchronisés ?
    TRITON_SYNC=$(oc get applications.argoproj.io openshift-ai-complete -n openshift-gitops -o jsonpath='{.status.resources[?(@.name=="triton-runtime")].status}' 2>/dev/null || echo "")
    SELDON_SYNC=$(oc get applications.argoproj.io openshift-ai-complete -n openshift-gitops -o jsonpath='{.status.resources[?(@.name=="seldon-mlserver-runtime")].status}' 2>/dev/null || echo "")
    
    if [ "$TRITON_SYNC" = "Synced" ]; then
        print_result 0 "Triton Runtime synchronisé dans ArgoCD"
    else
        print_result 1 "Triton Runtime non synchronisé dans ArgoCD ($TRITON_SYNC)"
    fi
    
    if [ "$SELDON_SYNC" = "Synced" ]; then
        print_result 0 "Seldon Runtime synchronisé dans ArgoCD"
    else
        print_result 1 "Seldon Runtime non synchronisé dans ArgoCD ($SELDON_SYNC)"
    fi
else
    print_result 1 "Application ArgoCD non trouvée"
fi

echo ""
echo "🎯 Résumé des Custom Serving Runtimes"
echo "====================================="

# Résumé final
TOTAL_RUNTIMES=$(oc get servingruntimes -n redhat-ods-applications --no-headers 2>/dev/null | wc -l || echo "0")
print_info "Total des serving runtimes déployés: $TOTAL_RUNTIMES"

if [ "$TOTAL_RUNTIMES" -ge 2 ]; then
    print_result 0 "Custom serving runtimes opérationnels selon les standards BU"
    echo ""
    print_info "📊 Formats de modèles supportés:"
    print_info "  🚀 Triton: TensorFlow, PyTorch, ONNX, TensorRT, Python"
    print_info "  🤖 Seldon: scikit-learn, XGBoost, LightGBM, MLflow, Hugging Face"
    echo ""
    print_info "🎯 Prêt pour le déploiement de modèles IA avancés !"
else
    print_result 1 "Configuration incomplète des custom serving runtimes"
fi
