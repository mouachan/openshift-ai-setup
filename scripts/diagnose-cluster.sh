#!/bin/bash

# Script de diagnostic du cluster OpenShift AI
# Identifie les problèmes et propose des solutions

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}[STEP]${NC} $1"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

echo "🔍 DIAGNOSTIC DU CLUSTER OPENSHIFT AI"
echo "═══════════════════════════════════════"

# 1. Vérification des nodes
log_step "Vérification des nodes"
oc get nodes -o wide

# 2. Vérification des pods problématiques
log_step "Pods en erreur"
ERROR_PODS=$(oc get pods -A | grep -E "(Error|CrashLoopBackOff|Pending|Failed)" | wc -l)
if [ "$ERROR_PODS" -gt 0 ]; then
    log_warning "Trouvé $ERROR_PODS pods problématiques"
    oc get pods -A | grep -E "(Error|CrashLoopBackOff|Pending|Failed)" | head -10
else
    log_success "Aucun pod problématique trouvé"
fi

# 3. Vérification des opérateurs critiques
log_step "État des opérateurs critiques"
OPERATORS=("rhods-operator" "knative-openshift" "openshift-gitops-operator" "openshift-pipelines-operator")
for operator in "${OPERATORS[@]}"; do
    if oc get pods -n openshift-operators | grep -q "$operator"; then
        STATUS=$(oc get pods -n openshift-operators | grep "$operator" | awk '{print $3}')
        if [[ "$STATUS" == "Running" ]]; then
            log_success "$operator: $STATUS"
        else
            log_error "$operator: $STATUS"
        fi
    else
        log_warning "$operator: Pod non trouvé"
    fi
done

# 4. Vérification d'ArgoCD
log_step "État d'ArgoCD"
if oc get applications.argoproj.io -n openshift-gitops >/dev/null 2>&1; then
    ARGOCD_STATUS=$(oc get applications.argoproj.io -n openshift-gitops -o jsonpath='{.items[0].status.sync.status}')
    ARGOCD_HEALTH=$(oc get applications.argoproj.io -n openshift-gitops -o jsonpath='{.items[0].status.health.status}')
    log_info "ArgoCD - Sync: $ARGOCD_STATUS, Health: $ARGOCD_HEALTH"
else
    log_error "ArgoCD non accessible"
fi

# 5. Vérification des ressources système
log_step "Ressources système"
echo "CPU et mémoire des nodes:"
oc adm top nodes

# 6. Vérification des événements récents
log_step "Événements récents (erreurs)"
oc get events --all-namespaces --sort-by='.lastTimestamp' | grep -E "(Error|Warning)" | tail -10

# 7. Recommandations
log_step "Recommandations"
echo "1. Redémarrer les opérateurs en CrashLoopBackOff:"
echo "   oc delete pod -n openshift-operators -l name=rhods-operator"
echo "   oc delete pod -n openshift-operators -l name=knative-openshift"

echo ""
echo "2. Vérifier les logs des opérateurs:"
echo "   oc logs -n openshift-operators deployment/rhods-operator"
echo "   oc logs -n openshift-operators deployment/knative-openshift"

echo ""
echo "3. Forcer une synchronisation ArgoCD:"
echo "   oc patch applications.argoproj.io openshift-ai-complete -n openshift-gitops --type='merge' -p='{\"spec\":{\"syncPolicy\":{\"automated\":{\"prune\":true,\"selfHeal\":true}}}}'"

echo ""
echo "4. Si le problème persiste, considérer un redémarrage du cluster ou une réinstallation propre"

log_step "Diagnostic terminé" 